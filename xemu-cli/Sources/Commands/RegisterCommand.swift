import Prism
import XemuFoundation
import XemuDebugger

struct RegisterCommand: Command {
    static var configuration = CommandConfiguration(
        name: "register",
        description: "Commands to access registers.",
        subcommands: [
            RegisterReadCommand.self,
            RegisterWriteCommand.self
        ]
    )
    
    func run(context: XemuCLI) throws(XemuError) {
        // TODO: print some help command generated from config
        print("use: register read")
    }
}
