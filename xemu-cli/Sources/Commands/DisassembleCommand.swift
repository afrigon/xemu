import Prism
import Foundation
import XemuFoundation
import XemuDebugger
import XemuAsm

struct DisassembleCommand: Command {
    static var configuration = CommandConfiguration(
        name: "disassemble",
        description: "Dissassemble of the code at the given pointer"
    )
    
    private var address: Int?
    
    init() {
        
    }
    
    init(arguments: [String]) {
        if let address = arguments.first {
            if address.starts(with: "0x") {
                if let stringValue = address.split(separator: "x").last, let value = Int(stringValue, radix: 16) {
                    self.address = value
                }
            } else {
                self.address = Int(address)
            }
        } else {
            self.address = nil
        }
    }
    
    func run(context: XemuCLI) throws(XemuError) {
        guard let emulator = context.emulator else {
            throw .emulatorNotSet
        }
        
        let registers = emulator.getRegisters()
        
        let address: Int = address ?? registers
            .compactMap { register in
                switch register {
                    case .programCounter(let r):
                        return r.value.int
                    default:
                        return nil
                }
            }
            .first ?? 0

        let count = 12
        let data = Data(emulator.getMemory()[address..<(address + (count * 3))]) // this is ugly but all instruction are at most 3 bytes on the 6502
        let result: DisassemblyResult
        
        switch emulator.arch {
            case .mos6502:
                result = MOS6502.Disassembler(data: data).disassemble(offset: address)
        }
        
        let space = "    "
        for element in result.elements[0..<count] {
            switch element {
                case .instruction(let addr, let raw, let value):
                    Output.shared.prism {
                        ForegroundColor(addr == address ? .green : .white) {
                            addr == address ? " \(Prompts.rightArrow)" : "  "
                            space
                            addr.hex(prefix: "0x", toLength: 4)
                        }
                        
                        space
                        
                        ForegroundColor(addr == address ? .green : .gray) {
                            raw
                                .map { $0.hex(toLength: 2) }
                                .joined(separator: " ")
                                .padding(toLength: 8, withPad: " ", startingAt: 0)
                        }
                        
                        space
                        
                        ForegroundColor(addr == address ? .green : .white) {
                            value
                        }
                    }
                default:
                    continue
            }
        }
    }
}
