import Foundation
import XemuFoundation
import XemuNES
import SwiftUI

struct FileCommand: Command {
    static let configuration = CommandConfiguration(
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
    
    func run(context: AppContext) async throws(XemuError) {
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
        context.emulator = NES() // TODO: change this to be dynamic based on file type
        
        try context.emulator?.load(program: data, saveData: nil)
        try context.emulator?.stepi()
        
        context.program = data
        
        let task = Task {
            let window = await SwiftUIWindow(
                title: "Nintendo",
                size: .init(width: 512, height: 480)
            ) {
                Text("Hello World")
            }
        
            await window.show()
            return window
        }
        
        if let window = await try task.value {
            context.windows.append(window)
        }
    }
}

