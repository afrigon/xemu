import XemuFoundation

struct ClearCommand: Command {
    static let configuration = CommandConfiguration(
        name: "clear",
        description: "Clear the output buffer."
    )
    
    func run(context: AppContext) throws(XemuError) {
        print("\u{001B}[2J")
        print("\u{001B}[H")
    }
}

