struct CommandConfiguration {
    let name: String
    let description: String
}

protocol Command {
    var configuration: CommandConfiguration { get }
    
    func run() throws
}
