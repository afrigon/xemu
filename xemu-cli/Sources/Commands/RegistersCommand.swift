import Prism
import XemuFoundation
import XemuDebugger

struct RegistersCommand: Command {
    static var configuration = CommandConfiguration(
        name: "registers",
        aliases: ["reg", "r"],
        description: "Display the status of the cpu registers"
    )
    
    func run(context: XemuCLI) throws(XemuError) {
        guard let emulator = context.emulator else {
            throw .emulatorNotSet
        }
        
        let registers = emulator.getRegisters()
        
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
    
    @MainActor
    private func printRegister(_ register: RegularRegister) {
        Output.shared.prism {
            ForegroundColor(.blue, "$\(register.name.padding(toLength: 2, withPad: " ", startingAt: 0))")
            ": "
            "\(register.value.uint.hex(prefix: "0x", padTo: register.size * 2))"
        }
    }
    
    @MainActor
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
