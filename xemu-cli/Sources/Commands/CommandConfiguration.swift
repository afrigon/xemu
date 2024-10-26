struct CommandConfiguration {
    let name: String
    let aliases: [String]
    let description: String
    let subcommands: [Command.Type]
    
    init(
        name: String,
        aliases: [String] = [],
        description: String,
        subcommands: [Command.Type] = []
    ) {
        self.name = name
        self.aliases = aliases
        self.description = description
        self.subcommands = subcommands
    }
}
