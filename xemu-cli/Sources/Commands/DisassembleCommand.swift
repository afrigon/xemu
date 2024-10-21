import Prism
import XemuFoundation
import XemuDebugger

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

        let instructions = emulator.disassemble(at: address, count: 8)
        let prefixes = instructions.map {
            $0.address == address ? " \(Prompts.rightArrow)" : "  "
        }
        let addresses = instructions.map {
            $0.address.hex(prefix: "0x", padTo: 4)
        }
        let values = instructions.map {
            $0.values.map { $0.hex(prefix: "", padTo: 2) }.joined(separator: " ")
        }
        let mnemonics = instructions.map(\.mnemonic)
        let operands = instructions.map(\.operands)
        
        let valuesMaxCount = values.map(\.count).max() ?? 0

        for i in 0..<instructions.count {
            let value = values[i].padding(toLength: valuesMaxCount, withPad: " ", startingAt: 0)
            
            let line = Prism(spacing: .custom) {
                if instructions[i].address == address {
                    ForegroundColor(.green(style: .bright)) {
                        "\(prefixes[i])   \(addresses[i])   "
                    }
                    ForegroundColor(.green(style: .default), value)
                    ForegroundColor(.green(style: .bright)) {
                        "   \(mnemonics[i]) \(operands[i])"
                    }
                } else {
                    "\(prefixes[i])   \(addresses[i])   "
                    ForegroundColor(.gray, value)
                    "   \(mnemonics[i]) \(operands[i])"
                }
            }
            
            Output.shared.prism {
                if instructions[i].address == address {
                    ForegroundColor(.green(style: .bright)) {
                        line.elements
                    }
                } else {
                    line.elements
                }
            }
        }
    }
}
