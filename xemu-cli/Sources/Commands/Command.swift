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
}
