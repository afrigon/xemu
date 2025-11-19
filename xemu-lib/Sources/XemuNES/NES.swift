import Foundation
import XemuCore
import XemuFoundation
import XemuDebugger
import XemuAsm

public final class NES: Emulator, BusDelegate {
    let cpu: MOS6502
    let apu: APU
    let ppu: PPU
    
    let bus: Bus = Bus()
    var cartridge: Cartridge? = nil
    
    public var controller1 = Controller()
    public var controller2 = Controller()

    let wram: Memory

    public let frameWidth = 256
    public let frameHeight = 240
    
    public var frameBuffer: [u8] {
        ppu.frame
    }
    
    public var audioBuffer: [f32]? {
        apu.buffer
    }
    
    public var cycles: u64 {
        cpu.cycles
    }

    public init() {
        cpu = .init(bus: bus)
        apu = .init(bus: bus)
        ppu = .init(bus: bus)
        wram = .init(.init(repeating: 0, count: 0x800))
        bus.delegate = self
        
        powerCycle()
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cpu = try container.decode(MOS6502.self, forKey: .cpu)
        apu = try container.decode(APU.self, forKey: .apu)
        ppu = try container.decode(PPU.self, forKey: .ppu)
        wram = try container.decode(Memory.self, forKey: .wram)
        cartridge = try container.decode(Cartridge.self, forKey: .cartridge)

        bus.delegate = self
        cpu.bus = bus
        apu.bus = bus
        ppu.bus = bus
    }
    
    func setNMI(_ value: Bool) {
        cpu.state.nmiSignal = value
    }

    func setIRQ(_ value: Bool) {
        cpu.state.irqSignal = value
    }
    
    func getDmcReadAddress() -> u16 {
        apu.dmc.address
    }
    
    func bus(bus: Bus, didSendReadSignalAt address: u16) -> u8? {
        if address == 0x4015 {
            return apu.read()
        }
        
        let mappedData = cartridge?.cpuRead(at: address) ?? bus.openBus
        
        return switch address {
            case 0x0000..<0x2000:
                wram.mirroredRead(at: address)
            case 0x2000..<0x4000:
                ppu.read(at: address)
            case 0x4016:
                controller1.read()
            case 0x4017:
                controller2.read()
            case 0x6000...0xFFFF:
                mappedData
            default:
                nil
        }
    }
    
    func bus(bus: Bus, didSendDebugReadSignalAt address: u16) -> u8? {
        if address == 0x4015 {
            return apu.debugRead()
        }
        
        let mappedData = cartridge?.cpuDebugRead(at: address) ?? bus.openBus
        
        return switch address {
            case 0x0000..<0x2000:
                wram.mirroredRead(at: address)
            case 0x2000..<0x4000:
                ppu.debugRead(at: address)
            case 0x4016:
                controller1.debugRead()
            case 0x4017:
                controller2.debugRead()
            case 0x6000...0xFFFF:
                mappedData
            default:
                nil
        }
    }
    
    func bus(bus: Bus, didSendWriteSignalAt address: u16, _ data: u8) {
        cartridge?.cpuWrite(data, at: address)
        
        switch address {
            case 0x0000..<0x2000:
                wram.mirroredWrite(data, at: address)
            case 0x2000..<0x4000:
                ppu.write(data, at: address)
            case 0x4000...0x4013:
                apu.write(data, at: address)
            case 0x4014:
                cpu.oamDma(data)
            case 0x4016:
                controller1.write(data)
                controller2.write(data)
            case 0x4017:
                apu.write(data, at: address)
            default:
                break
        }
    }
    
    func bus(bus: Bus, didSendReadVideoSignalAt address: u16) -> u8? {
        ppu.busAddress = address
        return cartridge?.ppuRead(at: address)
    }
    
    func bus(bus: Bus, didSendWriteVideoSignalAt address: u16, _ data: u8) {
        ppu.busAddress = address
        cartridge?.ppuWrite(data, at: address)
    }
    
    public func load(program: Data, saveData: Data? = nil) throws(XemuError) {
        let iNes = try iNesFile(program)
        cartridge = Cartridge(from: iNes, saveData: saveData)
    }
    
    public func powerCycle() {
        cpu.reset(type: .powerCycle)
        ppu.reset(type: .powerCycle)
        apu.reset(type: .powerCycle)
    }
    
    public func reset() {
        cpu.reset(type: .reset)
        ppu.reset(type: .reset)
        apu.reset(type: .reset)
    }
    
    @inline(__always) public func stepi() throws(XemuError) {
        try cpu.stepi()
    }
    
    public func stepFrame() throws(XemuError) {
        let frame = ppu.frameCount
        
        while ppu.frameCount == frame {
            try stepi()
        }
        
        // TODO: sync apu buffers with this
    }
    
    public func stepPPU(until cycle: Int) {
        ppu.step(until: cycle)
    }
    
    public func stepAPU() {
        apu.step()
    }

    enum CodingKeys: String, CodingKey {
        case cpu
        case ppu
        case apu
        case wram
        case cartridge
    }
}

extension NES: Debuggable {
    public var arch: Arch {
        .mos6502
    }
    
    public func getRegisters() -> [RegisterInfo] {
        cpu.getRegisters()
    }
    
    public func setRegister(name: String, value: u64) {
        cpu.setRegister(name: name, value: value)
    }
    
    public func getMemory(at address: Int) -> u8 {
        guard (0x0000...0xFFFF).contains(address) else {
            return 0 // TODO: maybe throw out of bound exception
        }
        
        return bus.debugRead(at: u16(address))
    }
    
    public func setMemory(_ data: u8, at address: Int) {
        guard (0x0000...0xFFFF).contains(address) else {
            return // TODO: maybe throw out of bound exception
        }
        
        bus.write(data, at: u16(address))
    }

    public var status: String {
        let pc = cpu.registers.pc
        let data = [
            bus.debugRead(at: pc),
            bus.debugRead(at: pc &+ 1),
            bus.debugRead(at: pc &+ 2)
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
                    let data = bus.debugRead(at: u16(value))
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .zeroPageX(let value):
                    let address = value &+ cpu.registers.x
                    let data = bus.debugRead(at: u16(address))
                    disasm += " @ \(address.hex(toLength: 2, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .zeroPageY(let value):
                    let address = value &+ cpu.registers.y
                    let data = bus.debugRead(at: u16(address))
                    disasm += " @ \(address.hex(toLength: 2, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .absolute(let value):
                    switch element.value {
                        case .jmp, .jsr:
                            break
                        default:
                            let data = bus.debugRead(at: value)
                            disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                    }
                case .absoluteX(let value):
                    let address = value &+ u16(cpu.registers.x)
                    let data = bus.debugRead(at: address)
                    disasm += " @ \(address.hex(toLength: 4, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .absoluteY(let value):
                    let address = value &+ u16(cpu.registers.y)
                    let data = bus.debugRead(at: address)
                    disasm += " @ \(address.hex(toLength: 4, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .indirect(let value):
                    let addressHI = value & 0xFF00
                    let addressLO = u8(value & 0x00FF)
                    let lo = bus.debugRead(at: value)
                    let hi = bus.debugRead(at: addressHI | u16(addressLO &+ 1))
                    let address = u16(hi) << 8 | u16(lo)
                    disasm += " = \(address.hex(toLength: 4, textCase: .uppercase))"
                case .indexedIndirect(let value):
                    let offset = value &+ cpu.registers.x
                    let lo = bus.debugRead(at: u16(offset))
                    let hi = bus.debugRead(at: u16(offset &+ 1))
                    let address = u16(hi) << 8 | u16(lo)
                    let data = bus.debugRead(at: address)
                    disasm += " @ \(offset.hex(toLength: 2, textCase: .uppercase))"
                    disasm += " = \(address.hex(toLength: 4, textCase: .uppercase))"
                    disasm += " = \(data.hex(toLength: 2, textCase: .uppercase))"
                case .indirectIndexed(let value):
                    let lo = bus.debugRead(at: u16(value))
                    let hi = bus.debugRead(at: u16(value &+ 1))
                    let address = u16(hi) << 8 | u16(lo)
                    let effectiveAddress = address &+ u16(cpu.registers.y)
                    let data = bus.debugRead(at: effectiveAddress)
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
