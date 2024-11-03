import Prism
import XemuFoundation
import XemuDebugger

struct ContextCommand: Command {
    static let configuration = CommandConfiguration(
        name: "context",
        description: "Display an overview of the emulator"
    )
    
    func run(context: AppContext) throws(XemuError) {
        guard let emulator = context.emulator else {
            throw .emulatorNotSet
        }
        
        divider(title: "registers")
        try RegisterReadCommand().run(context: context)

        divider(title: "stack")
        try StackCommand().run(context: context)
        
        divider(title: "code")
        try DisassembleCommand().run(context: context)
        divider()
    }
    
    // TODO: implement legend
    private func legend() {
        Output.shared.prism {
            "[ Legend: "
            ForegroundColor(.red, "Code")
            ForegroundColor(.magenta, "Stack")
            " ]"
        }
    }

    private func divider(title: String? = nil) {
        var width = Output.shared.currentSize.width
        
        if width <= 0 {
            width = 80
        }
        
        let titleSize = if let title {
            title.count + 2
        } else {
            0
        }
        
        let postfix = 10
        let prefix = width - (titleSize + postfix)
        
        Output.shared.prism {
            ForegroundColor(.gray) {
                String(
                    repeating: Prompts.horizontalLine,
                    count: prefix
                )
            }
            
            if let title {
                ForegroundColor(.cyan, " \(title) ")
            }
            
            ForegroundColor(.gray) {
                String(
                    repeating: Prompts.horizontalLine,
                    count: postfix
                )
            }
        }
    }
}
