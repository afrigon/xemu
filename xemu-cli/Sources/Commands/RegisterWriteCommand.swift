import Prism
import XemuFoundation
import XemuDebugger

struct RegisterWriteCommand: Command {
    static let configuration = CommandConfiguration(
        name: "write",
        description: "Modify a single register value."
    )
    
    let registerName: String?
    let value: UInt64

    init() {
        registerName = nil
        value = 0
    }
    
    init(arguments: [String]) {
        registerName = arguments.first
        value = arguments.last.flatMap {
            UInt64($0, radix: 16) ?? UInt64($0) // TODO: write some generic Int parsing function, would get solved instantly with an ArgumentDecoder
        } ?? 0
    }
    
    func run(context: AppContext) throws(XemuError) {
        guard let emulator = context.emulator else {
            throw .emulatorNotSet
        }
        
        if let registerName {
            emulator.setRegister(name: registerName, value: value)
        }
    }
}
