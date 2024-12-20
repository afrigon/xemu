import Prism
import XemuFoundation
import XemuDebugger

struct RegisterReadCommand: Command {
    static let configuration = CommandConfiguration(
        name: "read",
        description: "Dump the contents of one or more register values. If no register is specified, dumps them all."
    )
    
    let registerName: String?
    
    init() {
        registerName = nil
    }
    
    init(arguments: [String]) {
        registerName = arguments.first
    }
    
    func run(context: AppContext) throws(XemuError) {
        guard let emulator = context.emulator else {
            throw .emulatorNotSet
        }
        
        let registers = emulator.getRegisters()
        
        if let registerName {
            for register in registers where register.id.lowercased() == registerName.lowercased() {
                switch register {
                    case .regular(let r):
                        printRegister(r)
                    case .stack(let r):
                        printRegister(r)
                    case .programCounter(let r):
                        printRegister(r)
                    case .flags(let r):
                        printFlagRegister(r)
                }
            }
        } else {
            for register in registers {
                switch register {
                    case .regular(let r):
                        printRegister(r)
                    case .stack(let r):
                        printRegister(r)
                    case .programCounter(let r):
                        printRegister(r)
                    case .flags(let r):
                        printFlagRegister(r)
                }
            }
        }
    }
    
    private func printRegister(_ register: RegularRegister) {
        Output.shared.prism {
            ForegroundColor(.blue, "$\(register.name.padding(toLength: 2, withPad: " ", startingAt: 0))")
            ": "
            "\(register.value.uint.hex(prefix: "0x", toLength: register.size * 2))"
        }
    }
    
    private func printFlagRegister(_ register: FlagRegister) {
        let values = register.flags
            .map { flag in
                if flag.mask & register.value.uint != 0 {
                    ForegroundColor(.green) {
                        Bold(flag.displayName.uppercased())
                    }.description
                } else {
                    ForegroundColor(.red) {
                        flag.displayName.lowercased()
                    }.description
                }
            }
            .map(\.description)
            .joined(separator: " ")
        
        Output.shared.prism {
            ForegroundColor(.blue, "$\(register.name.padding(toLength: 2, withPad: " ", startingAt: 0))")
            ": "
            "[\(values)]"
        }
    }
}
