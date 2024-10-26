class PPU: Codable {
    weak var bus: Bus!
    
    var scanline: Int = 0
    
    init(bus: Bus) {
        self.bus = bus
    }
    
    func clock() {
        
    }
    
    enum CodingKeys: CodingKey {
        
    }
}
