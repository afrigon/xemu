import Foundation
import XemuFoundation

class MapperNROM: Mapper {
    var type: MapperType = .nrom
    
    let pgrrom: Memory
    let chrrom: Memory
    var sram: Memory

    required init(from iNes: iNesFile, saveData: Data) {
        pgrrom = .init(iNes.pgrrom)
        chrrom = .init(iNes.chrrom)
        sram = .init(saveData)
    }
    
    func cpuRead(at address: u16) -> u8? {
        switch address {
            case 0x6000..<0x8000:
                sram.read(at: address - 0x6000)
            case 0x8000...0xFFFF:
                pgrrom.mirroredRead(at: address - 0x8000)
            default:
                nil
        }
    }
    
    func cpuWrite(_ data: u8, at address: u16) {
        switch address {
            case 0x6000..<0x8000:
                sram.write(data, at: address - 0x6000)
            case 0x8000...0xFFFF:
                // TODO: should this be allowed in ROM ?
                pgrrom.mirroredWrite(data, at: address - 0x8000)
            default:
                break
        }
    }
    
    func ppuRead(at address: u16) -> u8? {
        if address < 0x2000 {
            chrrom.mirroredRead(at: address)
        } else {
            nil
        }
    }
    
    func ppuWrite(_ data: u8, at address: u16) {
        // chr is read-only, do nothing
    }
}
