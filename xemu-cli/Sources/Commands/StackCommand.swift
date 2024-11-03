import Prism
import XemuFoundation
import XemuDebugger
import XemuAsm

struct StackCommand: Command {
    static let configuration = CommandConfiguration(
        name: "stack",
        description: "Display memory around the stack pointer"
    )
    
    func run(context: AppContext) throws(XemuError) {
        guard let emulator = context.emulator else {
            throw .emulatorNotSet
        }
        
        let registers = emulator.getRegisters()
        
        let sp = registers
            .compactMap { register in
                switch register {
                    case .stack(let r):
                        return r
                    default:
                        return nil
                }
            }
            .first
        
        guard let sp else {
            return
        }
        
        // TODO: redo this
//        printStack(
//            memory: emulator.getMemory,
//            stackBaseAddress: emulator.arch.stackBaseAddress,
//            sp: sp
//        )
    }
    
    @MainActor
    private func printStack(
        memory: [u8],
        stackBaseAddress: Int,
        sp: RegularRegister,
        countBefore: Int = 0,
        countAfter: Int = 8
    ) {
        let stackEffectiveAddress = Int(sp.value.uint) + stackBaseAddress
        let start = stackEffectiveAddress - countBefore
        let end = stackEffectiveAddress + countAfter
        
        for address in start..<end {
            Output.shared.prism {
                ForegroundColor(.cyan, address.hex(prefix: "0x", toLength: 4))
                Prompts.verticalLine
                (address - start).hex(prefix: "0x", toLength: 2)
                ": "
                memory[address].hex(prefix: "0x", toLength: 2)
                
                if address == stackEffectiveAddress {
                    ForegroundColor(.blue(style: .bright), "   \(Prompts.leftArrow) $\(sp.name)")
                }
            }
        }
    }
}
