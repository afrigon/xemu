import XemuFoundation

class PPU: Codable {
    weak var bus: Bus!
    
    var scanline: Int = 0
    
    var control: u8 = 0
    var status: u8 = 0

    init(bus: Bus) {
        self.bus = bus
    }
    
    func clock() {
        
    }
    
    enum CodingKeys: CodingKey {
        case control
        case status
        case scanline
    }
}
