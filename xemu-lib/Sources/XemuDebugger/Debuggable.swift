import XemuCore
import XemuFoundation
import XemuAsm

public protocol Debuggable: Emulator {
    var arch: Arch { get }
    var status: String { get }

    func clock() throws(XemuError)
    func stepi() throws(XemuError)
    
    func getRegisters() -> [RegisterInfo]
    func setRegister(name: String, value: u64)
    
    func getMemory(in range: Range<Int>) -> [u8]
    func setMemory(address: Int, value: u8)
}
