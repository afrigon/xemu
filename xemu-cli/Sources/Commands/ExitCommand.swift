import Darwin
import XemuFoundation

struct ExitCommand: Command {
    static let configuration = CommandConfiguration(
        name: "exit",
        description: "Clear the output buffer."
    )
    
    func run(context: AppContext) throws(XemuError) {
        Darwin.exit(0)
    }
}

