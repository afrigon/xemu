import Foundation
import XemuFoundation

protocol Mapper: Codable {
    var type: MapperType { get }
    
    var pgrrom: Memory { get }
    var chrrom: Memory { get }
    var sram: Memory { get }
    var vram: Memory { get }

    init(from iNes: iNesFile, saveData: Data)
    
    func cpuDebugRead(at address: u16) -> u8?
    func cpuRead(at address: u16) -> u8?
    func cpuWrite(_ data: u8, at address: u16)
    
    func ppuDebugRead(at address: u16) -> u8?
    func ppuRead(at address: u16) -> u8?
    func ppuWrite(_ data: u8, at address: u16)
}

extension Mapper {
    func eraseToAnyMapper() -> AnyMapper {
        AnyMapper(mapper: self)
    }
}

class AnyMapper: Codable {
    let type: MapperType
    let mapper: Mapper
    
    init(mapper: Mapper) {
        self.type = mapper.type
        self.mapper = mapper
    }
    
    required init(from iNes: iNesFile, saveData: Data) {
        self.type = iNes.mapper
        
        switch type {
            case .nrom:
                self.mapper = MapperNROM(from: iNes, saveData: saveData)
            case .mmc1:
                self.mapper = MapperMMC1(from: iNes, saveData: saveData)
            case .cnrom:
                self.mapper = MapperCNROM(from: iNes, saveData: saveData)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case mapper
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(MapperType.self, forKey: .type)
        
        switch type {
            case .nrom:
                self.mapper = try container.decode(MapperNROM.self, forKey: .mapper)
            case .mmc1:
                self.mapper = try container.decode(MapperMMC1.self, forKey: .mapper)
            case .cnrom:
                self.mapper = try container.decode(MapperCNROM.self, forKey: .mapper)
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(mapper, forKey: .type)
    }
}
