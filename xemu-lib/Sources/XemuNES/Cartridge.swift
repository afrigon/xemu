import Foundation
import XemuFoundation

class Cartridge: Codable {

    let mapper: AnyMapper
    
    var saveData: Data {
        Data(mapper.mapper.sram.data)
    }
    
    init(from iNes: iNesFile, saveData: Data? = nil) {
        // TODO: generate the size of sram from file, probably default to this if no sram info
        mapper = AnyMapper(from: iNes, saveData: saveData ?? .init(repeating: 0, count: 0x2000))
    }
    
    func cpuRead(at address: u16) -> u8? {
        mapper.mapper.cpuRead(at: address)
    }
    
    func cpuWrite(_ data: u8, at address: u16) {
        mapper.mapper.cpuWrite(data, at: address)
    }
    
    func ppuRead(at address: u16) -> u8? {
        mapper.mapper.ppuRead(at: address)
    }
    
    func ppuWrite(_ data: u8, at address: u16) {
        mapper.mapper.ppuWrite(data, at: address)
    }
}
