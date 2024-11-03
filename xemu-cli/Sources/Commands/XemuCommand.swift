import Prism
import XemuFoundation

struct XemuCommand: Command {
    static let configuration = CommandConfiguration(
        name: "xemu",
        description: "The entry point for Xemu commands",
        subcommands: [
            BreakCommand.self,
            ClearCommand.self,
            ContextCommand.self,
            DisassembleCommand.self,
            ExitCommand.self,
            FileCommand.self,
            RegisterCommand.self,
            StackCommand.self,
            StepInstructionCommand.self
        ]
    )
    
    let subcommand: String?
    
    init() {
        subcommand = nil
    }
    
    init(arguments: [String]) {
        subcommand = arguments.first
    }
    
    func run(context: AppContext) throws(XemuError) {
        if let subcommand {
            Output.shared.prism {
                ForegroundColor(.red, "error: ")
                "'\(subcommand)' is not a valid command."
            }
        }
    }
}

