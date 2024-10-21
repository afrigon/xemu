import Foundation
import XemuFoundation

struct FileCommand: Command {
    static var configuration = CommandConfiguration(
        name: "file",
        description: "Loads the specified file into xemu"
    )
    
    private let filepath: URL?
    
    init() {
        filepath = nil
    }
    
    init(arguments: [String]) {
        if let path = arguments.first {
            filepath = URL(filePath: path)
        } else {
            filepath = nil
        }
    }
    
    func run(context: XemuCLI) throws(XemuError) {
        guard let filepath else {
            throw .importError
        }
        
        if context.program != nil {
            if !Prompts.areYouSure(prompt: "A program is already running, are you sure? [y/n]") {
                return
            }
        }
        
        let data: Data
        
        do {
            data = try Data(contentsOf: filepath)
        } catch {
            throw .fileSystemError
        }
        
        // TODO: set emu, pause, reset, load logic

        try context.emulator?.load(program: data)
        context.program = data
    }
}

