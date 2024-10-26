import Foundation
import Clibedit
import Prism
import XemuFoundation
import XemuCore
import XemuDebugger
import XemuNES

class XemuCLI {
    var emulator: (any Emulator & Debuggable)? = MockSystem()  // TODO: remove this and implement an emulator command
    var program: Data? = nil
    var breakpoints: [Breakpoint] = []
    
    @MainActor
    func run() {
        Output.shared.startMonitoring()
        
        run("""
file /Users/xehos/Downloads/02-implied.nes
context
""")

        let prompt = Prism { ForegroundColor(.green, Prompts.prompt) }
        var lastCommand: String = ""
        
        while let line = readline(prompt.description) {
            var input = String(cString: line)
            free(line)
            
            // repeat last command when empty input.
            if input.isEmpty {
                input = lastCommand
            } else {
                if input != lastCommand {
                    add_history(input)
                    lastCommand = input
                }
            }
                
            run(input)
        }
    }
    
    @MainActor
    func run(_ input: String) {
        let commands = input
            .split(separator: "\n")
            .map(String.init)
        
        for command in commands {
            let arguments = ["xemu"] + command
                .split(separator: " ")
                .map(String.init)
            
            do throws(XemuError) {
                guard let command = XemuCommand.parse(from: arguments) else {
                    continue
                }
                
                try command.run(context: self)
            } catch let error {
                Output.shared.print(error.message.stringKey ?? "")
            }
        }
        
    }
}
