import XemuFoundation

public class NES: Codable, BusDelegate {
    let cpu: MOS6502
//    let apu: APU
//    let ppu: PPU
    let bus: Bus = Bus()
    
    init() {
        cpu = .init(bus: bus)
//        apu = .init(bus: bus)
//        ppu = .init(bus: bus)
        bus.delegate = self
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cpu = try container.decode(MOS6502.self, forKey: .cpu)
//        apu = try container.decode(APU.self, forKey: .apu)
//        ppu = try container.decode(PPU.self, forKey: .ppu)
        
        bus.delegate = self
        cpu.bus = bus
//        apu.bus = bus
//        ppu.bus = bus
    }
    
    func bus(bus: Bus, didSendReadSignalAt address: u16) -> u8 {
        return 0
    }
    
    func bus(bus: Bus, didSendWriteSignalAt address: u16, _ data: u8) {
        
    }
    
    enum CodingKeys: CodingKey {
        case cpu
//        case apu
//        case ppu
    }
}
