import Prism
import XemuFoundation

struct StepInstructionCommand: Command {
    static let configuration = CommandConfiguration(
        name: "stepi",
        description: "Steps through a single instruction. Steps into calls."
    )
    
    func run(context: AppContext) throws(XemuError) {
        guard let emulator = context.emulator else {
            throw .emulatorNotSet
        }
        
        try emulator.stepi()
        
        try ContextCommand().run(context: context)
    }
}
