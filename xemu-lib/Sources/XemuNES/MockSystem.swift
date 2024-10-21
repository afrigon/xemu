import Foundation
import XemuFoundation
import XemuCore
import XemuDebugger

public class MockSystem: Emulator, BusDelegate {
    let cpu: Chip6502
    let bus: Bus = .init()
    var ram: [UInt8] = .init(repeating: 0, count: 0xFFFF)
    var cartridge: Cartridge?

    public init() {
        cpu = .init(bus: bus)
        bus.delegate = self
    }
    
    func bus(bus: Bus, didSendReadSignalAt address: UInt16) -> UInt8 {
        guard address < ram.count else {
            return 0
        }
        
        return ram[address]
    }
    
    func bus(bus: Bus, didSendWriteSignalAt address: UInt16, _ data: UInt8) {
        guard address < ram.count else {
            return
        }
        
        ram[address] = data
    }
    
    public func insert(cartridge: Cartridge) throws(XemuError) {
        self.cartridge = cartridge
    }
    
    public func load(program: Data) throws(XemuError) {
        let file = try iNesFile(program)
        
        file.pgrRom.copyBytes(to: &ram[0x8000], count: file.pgrRom.count)
        file.pgrRom.copyBytes(to: &ram[0x8000 + file.pgrRom.count], count: file.pgrRom.count)
        
        cpu.pc = bus.read16(at: Chip6502.InterruptType.reset.address)
        cpu.pc = 0xc000 // TODO: remove this
    }
    
    public func clock() throws(XemuError) {
        _ = try cpu.clock()
    }
}

extension MockSystem: Debuggable {
    public var stackBaseAddress: Int {
        Chip6502.stackBaseAddress
    }
    
    public func getRegisters() -> [RegisterInfo] {
        cpu.getRegisters()
    }
    
    public func setRegister(name: String, value: UInt64) {
        cpu.setRegister(name: name, value: value)
    }
    
    public func getMemory() -> [UInt8] {
        ram
    }
    
    public func setMemory(address: Int, value: UInt8) {
        ram[Int(address)] = value
    }

    public func stepi() throws(XemuError) {
        var state: Chip6502.State
        
        repeat {
            state = try cpu.clock()
        } while !state.complete
    }
    
    @MainActor
    public func disassemble(at address: Int, count: Int) -> [InstructionInfo] {
        var address = address
        
        return (0..<count).compactMap { _ in
            guard address < 0xFFFF else {
                return nil
            }
            
            let startAddress = address
            let opcode = bus.read(at: UInt16(address))
            let instruction = Chip6502.instructions[Int(opcode)]
            
            address += 1

            guard let instruction else {
                return .init(
                    address: startAddress,
                    values: [opcode],
                    mnemonic: "bad",
                    operands: ""
                )
            }
            
            switch instruction.addressingMode {
                case .implied, .accumulator:
                    return .init(
                        address: startAddress,
                        values: [opcode],
                        mnemonic: instruction.mnemonic.rawValue,
                        operands: ""
                    )
                case .immediate:
                    let operand = bus.read(at: UInt16(address))
                    address += 1

                    return .init(
                        address: startAddress,
                        values: [opcode, operand],
                        mnemonic: instruction.mnemonic.rawValue,
                        operands: operand.hex(prefix: "#$", padTo: 2)
                    )
                case .relative:
                    let operand = bus.read(at: UInt16(address))
                    address += 1

                    return .init(
                        address: startAddress,
                        values: [opcode, operand],
                        mnemonic: instruction.mnemonic.rawValue,
                        operands: operand.hex(prefix: "$", padTo: 2)
                    )
                case .zeroPage(let index):
                    let operand = bus.read(at: UInt16(address))
                    address += 1
                    
                    let index = index.map {
                        switch $0 {
                            case .x: ",X"
                            case .y: ",Y"
                        }
                    } ?? ""
                    
                    return .init(
                        address: startAddress,
                        values: [opcode, operand],
                        mnemonic: instruction.mnemonic.rawValue,
                        operands: operand.hex(prefix: "$", padTo: 2) + index
                    )
                case .absolute(let index):
                    let lo = bus.read(at: UInt16(address))
                    address += 1
                    
                    let hi = bus.read(at: UInt16(address))
                    address += 1
                    
                    let operand = UInt16(hi) << 8 | UInt16(lo)

                    let index = index.map {
                        switch $0 {
                            case .x: ",X"
                            case .y: ",Y"
                        }
                    } ?? ""
                    
                    return .init(
                        address: startAddress,
                        values: [opcode, lo, hi],
                        mnemonic: instruction.mnemonic.rawValue,
                        operands: operand.hex(prefix: "$", padTo: 4) + index
                    )
                case .indirect(let index):
                    if let index {
                        let lo = bus.read(at: UInt16(address))
                        address += 1
                        
                        let hi = bus.read(at: UInt16(address))
                        address += 1
                        
                        let operand = UInt16(hi) << 8 | UInt16(lo)
                        let operandString = switch index {
                            case .x:
                                "(\(operand.hex(prefix: "$", padTo: 2)),X)"
                            case .y:
                                "(\(operand.hex(prefix: "$", padTo: 2))),Y"
                        }
                        
                        return .init(
                            address: startAddress,
                            values: [opcode, lo, hi],
                            mnemonic: instruction.mnemonic.rawValue,
                            operands: operandString
                        )
                    } else {
                        let operand = bus.read(at: UInt16(address))
                        address += 1
                        
                        return .init(
                            address: startAddress,
                            values: [opcode, operand],
                            mnemonic: instruction.mnemonic.rawValue,
                            operands: "(\(operand.hex(prefix: "$", padTo: 4)))"
                        )
                    }
            }
        }
    }
}
