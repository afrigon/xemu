import Foundation
import XemuFoundation
import XemuCore
import XemuDebugger
import XemuAsm

public class MockSystem: Emulator, BusDelegate {
    let cpu: MOS6502
    let bus: Bus = .init()
    var wram: Memory = .init(count: 0x0800)
    var cartridge: Cartridge? = nil
    var cycles: UInt64 = 0
    
    enum CodingKeys: CodingKey {
        case cpu
        case wram
        case cartridge
        case cycles
    }

    public init() {
        cpu = .init(bus: bus)
        bus.delegate = self
    }
    
    func nmiSignal() -> Bool {
        false
    }
    
    func irqSignal() -> Bool {
        false
    }
    
    func bus(bus: Bus, didSendReadSignalAt address: u16) -> u8? {
        let mappedData = cartridge?.cpuRead(at: address) ?? bus.openBus
        
        switch address {
            case 0x0000..<0x2000:
                return wram.mirroredRead(at: address)
            case 0x6000...0xFFFF:
                return mappedData
            default:
                return bus.openBus
        }
    }
    
    func bus(bus: Bus, didSendWriteSignalAt address: u16, _ data: u8) {
        cartridge?.cpuWrite(data, at: address)
        
        switch address {
            case 0x0000..<0x2000:
                return wram.mirroredWrite(data, at: address)
            default:
                break
        }
    }
    
    public func load(program: Data, saveData: Data? = nil) throws(XemuError) {
        let iNes = try iNesFile(program)
        cartridge = Cartridge(from: iNes, saveData: saveData)
    }
    
    public func reset() {
        cycles = 0
        cpu.state.tick = 0
        cpu.state.servicing = .reset
    }
    
    public func clock() throws(XemuError) {
        try cpu.clock()
        cycles &+= 1
    }
}

extension MockSystem: Debuggable {
    public var arch: Arch {
        .mos6502
    }
    
    public func getRegisters() -> [RegisterInfo] {
        cpu.getRegisters()
    }
    
    public func setRegister(name: String, value: u64) {
        cpu.setRegister(name: name, value: value)
    }
    
    public func getMemory(in range: Range<Int>) -> [u8] {
        range.compactMap {
            guard (0x0000...0xFFFF).contains($0) else {
                return nil
            }
            
            return bus.read(at: u16($0))
        }
    }
    
    public func setMemory(address: Int, value: u8) {
        guard (0x0000...0xFFFF).contains(address) else {
            return // TODO: maybe throw out of bound exception
        }
        
        bus.write(value, at: u16(address))
    }

    public func stepi() throws(XemuError) {
        // run the first cycle
        try clock()
        
        // finish the instruction
        while cpu.state.tick >= 1 && !cpu.state.halted {
            try clock()
        }
    }
    
    public var status: String {
        let pc = cpu.registers.pc
        let data = [
            bus.read(at: pc),
            bus.read(at: pc &+ 1),
            bus.read(at: pc &+ 2)
        ]
        let disassembler = XemuAsm.MOS6502.Disassembler(data: Data(data))
        
        guard let element = disassembler.disassemble(offset: Int(pc)).elements.first else {
            return "Failed to disassemble at PC"
        }
        
        var items: [String] = []
        
        items.append(element.address.hex(toLength: 4, textCase: .uppercase))
            
        let raw = element.raw
            .map { $0.hex(toLength: 2, textCase: .uppercase) }
            .joined(separator: " ")
            .padding(toLength: 8, withPad: " ", startingAt: 0)

        var disasm = element.value.asm(offset: Int(pc)).uppercased()
            
        if let addressingMode = element.value.addressingMode {
            switch addressingMode {
                case .accumulator:
                    disasm += "A"
                case .relative(let value):
                    disasm = disasm.dropLast(4) + (Int(pc) + Int(value) + 2).hex(toLength: 4, textCase: .uppercase)
                case .zeroPage(let value):
                    let data = bus.read(at: u16(value))
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .zeroPageX(let value):
                    let address = value &+ cpu.registers.x
                    let data = bus.read(at: u16(address))
                    disasm += " @ \(address.hex(toLength: 2, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .zeroPageY(let value):
                    let address = value &+ cpu.registers.y
                    let data = bus.read(at: u16(address))
                    disasm += " @ \(address.hex(toLength: 2, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .absolute(let value):
                    switch element.value {
                        case .jmp, .jsr:
                            break
                        default:
                            let data = bus.read(at: value)
                            disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                    }
                case .absoluteX(let value):
                    let address = value &+ u16(cpu.registers.x)
                    let data = bus.read(at: address)
                    disasm += " @ \(address.hex(toLength: 4, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .absoluteY(let value):
                    let address = value &+ u16(cpu.registers.y)
                    let data = bus.read(at: address)
                    disasm += " @ \(address.hex(toLength: 4, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .indirect(let value):
                    let addressHI = value & 0xFF00
                    let addressLO = u8(value & 0x00FF)
                    let lo = bus.read(at: value)
                    let hi = bus.read(at: addressHI | u16(addressLO &+ 1))
                    let address = u16(hi) << 8 | u16(lo)
                    disasm += " = \(address.hex(toLength: 4, textCase: .uppercase))"
                case .indexedIndirect(let value):
                    let offset = value &+ cpu.registers.x
                    let lo = bus.read(at: u16(offset))
                    let hi = bus.read(at: u16(offset &+ 1))
                    let address = u16(hi) << 8 | u16(lo)
                    let data = bus.read(at: address)
                    disasm += " @ \(offset.hex(toLength: 2, textCase: .uppercase))"
                    disasm += " = \(address.hex(toLength: 4, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .indirectIndexed(let value):
                    let lo = bus.read(at: u16(value))
                    let hi = bus.read(at: u16(value &+ 1))
                    let address = u16(hi) << 8 | u16(lo)
                    let effectiveAddress = address &+ u16(cpu.registers.y)
                    let data = bus.read(at: effectiveAddress)
                    disasm += " = \(address.hex(toLength: 4, textCase: .uppercase))"
                    disasm += " @ \(effectiveAddress.hex(toLength: 4, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                default:
                    break
            }
        }
        
        let code = [
            raw,
            disasm.padding(toLength: 30, withPad: " ", startingAt: 0)
        ]
        
        items.append(code.joined(separator: element.value.official ? "  " : " *"))
        
        let registers: [String] = [
            "A:\(cpu.registers.a.hex(toLength: 2, textCase: .uppercase))",
            "X:\(cpu.registers.x.hex(toLength: 2, textCase: .uppercase))",
            "Y:\(cpu.registers.y.hex(toLength: 2, textCase: .uppercase))",
            "P:\(cpu.registers.p.value(b: false).hex(toLength: 2, textCase: .uppercase))",
            "SP:\(cpu.registers.s.hex(toLength: 2, textCase: .uppercase))",
            "CYC:\(cycles)"
        ]
        
        items.append(registers.joined(separator: " "))
        
        return items.joined(separator: "  ")
    }
}
