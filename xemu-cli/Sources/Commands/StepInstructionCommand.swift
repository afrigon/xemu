import Prism
import XemuFoundation

struct StepInstructionCommand: Command {
    static var configuration = CommandConfiguration(
        name: "stepi",
        aliases: ["si"],
        description: "Steps through a single instruction. Steps into calls."
    )
    
    func run(context: XemuCLI) throws(XemuError) {
        guard let emulator = context.emulator else {
            throw .emulatorNotSet
        }
        
        try emulator.stepi()
        
        try ContextCommand().run(context: context)
    }
}
