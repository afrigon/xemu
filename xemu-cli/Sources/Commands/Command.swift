import XemuFoundation

protocol Command {
    
    @MainActor
    static var configuration: CommandConfiguration { get }
    
    init()
    init(arguments: [String])
    
    @MainActor
    func run(context: XemuCLI) throws(XemuError)
}

extension Command {
    init(arguments: [String]) {
        self.init()
    }
    
    @MainActor
    static func parse(from arguments: [String]) -> Command? {
        guard let name = arguments.first else {
            return nil
        }
        
        // TODO: add check for command collision instead of just taking the first match
        
        // make sure we match with an alias or the beginning of the command name
        guard Self.configuration.aliases.contains(name) || Self.configuration.name.hasPrefix(name) else {
            return nil
        }
        
        let arguments = [String](arguments.dropFirst())
        
        for subcommand in Self.configuration.subcommands {
            if let command = subcommand.parse(from: arguments) {
                return command
            }
        }
        
        return Self(arguments: arguments)
    }
}
