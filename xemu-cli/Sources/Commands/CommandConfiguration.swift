struct CommandConfiguration {
    let name: String
    let aliases: [String]
    let description: String
    
    init(name: String, aliases: [String] = [], description: String) {
        self.name = name
        self.aliases = aliases
        self.description = description
    }
}
