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
    
    func getMemory(at address: Int) -> u8
    func setMemory(_ data: u8, at address: Int)
}

extension Debuggable {
    public func getMemory(in range: ClosedRange<Int>) -> [u8] {
        range.map { getMemory(at: $0) }
    }
    
    public func getMemory(in range: Range<Int>) -> [u8] {
        range.map { getMemory(at: $0) }
    }
    
    public func getString(at address: Int) -> String {
        var result: String = ""
        var i = 0
        
        while true {
            let data = getMemory(at: address &+ i)
            
            if data == 0x00 {
                break
            }
            
            result += String(UnicodeScalar(data))
            i &+= 1
        }
        
        return result
    }
}
