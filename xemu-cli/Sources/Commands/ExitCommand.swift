import Darwin
import XemuFoundation

struct ExitCommand: Command {
    static var configuration = CommandConfiguration(
        name: "exit",
        aliases: ["quit"],
        description: "Clear the output buffer."
    )
    
    func run(context: XemuCLI) throws(XemuError) {
        Darwin.exit(0)
    }
}

