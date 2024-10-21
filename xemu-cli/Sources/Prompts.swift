import Clibedit

class Prompts {
    static let prompt: String = "xemu➤ "
    
    static let leftArrow: String = "←"
    static let rightArrow: String = "→"
    static let downArrow: String = "↳"
    
    static let horizontalLine: String = "─"
    static let verticalLine: String = "│"
    
    static let check: String = "✓"
    static let cross: String = "✘"
    static let circle: String = "●"
    
    static func areYouSure(prompt: String) -> Bool {
        guard let input = readline("\(prompt) (y/n): ") else {
            return false
        }
        
        let value = String(cString: input).lowercased()
        free(input)
        
        return value == "y" || value == "yes"
    }
}
