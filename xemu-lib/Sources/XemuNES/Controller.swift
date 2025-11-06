import XemuFoundation

public final class Controller: Codable {
    public var input: u8 = 0
    var data: u8 = 0
    var strobe: Bool = false
    
    func read() -> u8 {
        if strobe {
            self.data = input
        }
        
        defer { data >>= 1 }
        
        return data & 1
    }
    
    func write(_ data: u8) {
        strobe = Bool(data & 1)
        
        if strobe {
            self.data = input
        }
    }
}
