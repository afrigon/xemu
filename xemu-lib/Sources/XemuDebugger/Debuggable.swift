import XemuCore
import XemuFoundation
import XemuAsm

public protocol Debuggable: Emulator {
    var arch: Arch { get }
    
    func getRegisters() -> [RegisterInfo]
    func setRegister(name: String, value: u64)
    
    func getMemory() -> [u8]
    func setMemory(address: Int, value: u8)
    
    @MainActor
    func stepi() throws(XemuError)
}
