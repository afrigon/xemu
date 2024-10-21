import Foundation
import Clibedit
import Prism
import XemuFoundation
import XemuCore
import XemuDebugger
import XemuNES

class XemuCLI {
    private var commands: CommandRepository = CommandRepository()
    var emulator: (any Emulator & Debuggable)? = nil
    var program: Data? = nil

    func setup() {
        emulator = MockSystem() // TODO: remove this and implement an emulator command
        commands.register(FileCommand.self)
        commands.register(RegistersCommand.self)
        commands.register(ContextCommand.self)
        commands.register(StackCommand.self)
        commands.register(DisassembleCommand.self)
        commands.register(StepInstructionCommand.self)
        commands.register(ClearCommand.self)
        commands.register(ExitCommand.self)
    }

    @MainActor
    func run() {
        setup()
        
        let prompt = Prism {
            ForegroundColor(.green, Prompts.prompt)
        }
        
        Output.shared.startMonitoring()
        
        try? FileCommand(arguments: ["/Users/xehos/Downloads/nestest.nes"]).run(context: self)

        try? ContextCommand().run(context: self)
        
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
            
            let arguments = input.split(separator: " ").map(String.init)
            
            do throws(XemuError) {
                try run(arguments: arguments)
            } catch let error {
                Output.shared.print(error.message.stringKey ?? "")
            }
        }
    }
    
    @MainActor
    func run(arguments: [String]) throws(XemuError) {
        guard let first = arguments.first else {
            return
        }
        
        let arguments = Array(arguments.dropFirst())
        
        if let command = commands.findCommandBy(name: first, arguments: arguments) {
            try command.run(context: self)
            
            return
        }
        
        throw .unknownCommand
    }
}
