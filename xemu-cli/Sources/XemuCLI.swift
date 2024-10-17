import Clibedit

class XemuCLI {
    var commands: Group = Group()
    
    func run() {
        setup()
        
        while let line = readline(Prompts.prompt) {
            let input = String(cString: line)
            
            free(line)
            
            if !input.isEmpty {
                add_history(input)
            }
            
            let arguments = input.split(separator: " ").map(String.init)
            
            do {
                try commands.run(.init(arguments: arguments))
            } catch let error {
                print(error)
            }
        }
    }
    
    func setup() {
        
    }
}
