import XemuFoundation

struct ClearCommand: Command {
    static var configuration = CommandConfiguration(
        name: "clear",
        description: "Clear the output buffer."
    )
    
    func run(context: XemuCLI) throws(XemuError) {
        print("\u{001B}[2J")
        print("\u{001B}[H")
    }
}

