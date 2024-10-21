import XemuCore

class CommandRepository {
    var commands: [Command.Type] = []
    
    @MainActor
    var names: [String] {
        commands.map { $0.configuration.name }
    }
    
    func register(_ command: Command.Type) {
        commands.append(command)
    }
    
    @MainActor
    func findCommandBy(name: String, arguments: [String]) -> Command? {
        for command in commands {
            if command.configuration.name == name || command.configuration.aliases.contains(name) {
                // TODO: take in and parse arguments
                return command.init(arguments: arguments)
            }
        }
        
        return nil
    }
}
