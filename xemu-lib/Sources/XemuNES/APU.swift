class APU: Codable {
    weak var bus: Bus!
    
    init(bus: Bus) {
        self.bus = bus
    }
    
    func clock() {
        
    }
    
    enum CodingKeys: CodingKey {
    }
}
