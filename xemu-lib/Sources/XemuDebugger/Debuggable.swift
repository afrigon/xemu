import XemuCore
import XemuFoundation

public protocol Debuggable: Emulator {
    var stackBaseAddress: Int { get }
    
    func getRegisters() -> [RegisterInfo]
    
    func setRegister(name: String, value: UInt64)
    
    func getMemory() -> [UInt8]
    
    func setMemory(address: Int, value: UInt8)
    
    @MainActor
    func stepi() throws(XemuError)
    
    @MainActor
    func disassemble(at address: Int, count: Int) -> [InstructionInfo]
}
