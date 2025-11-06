import Foundation
import XemuFoundation

final class MapperNROM: Mapper {
    var type: MapperType = .nrom
    
    let pgrrom: Memory
    let chrrom: Memory
    var sram: Memory
    
    let vram: Memory
    let nametableLayout: NametableLayout

    required init(from iNes: iNesFile, saveData: Data) {
        pgrrom = .init(iNes.pgrrom)
        chrrom = .init(iNes.chrrom)
        sram = .init(saveData)
        vram = .init(.init(repeating: 0, count: 0x800))
        nametableLayout = iNes.nametableLayout
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
            default:
                break
        }
    }
    
    func ppuRead(at address: u16) -> u8? {
        switch address {
            case 0x0000..<0x2000:
                chrrom.mirroredRead(at: address)
            case 0x2000..<0x4000:
                vram.read(at: nametableLayout.map(address))
            default:
                nil
        }
    }
    
    func ppuWrite(_ data: u8, at address: u16) {
        switch address {
            case 0x0000..<0x2000:
                chrrom.mirroredWrite(data, at: address)
            case 0x2000..<0x4000:
                vram.write(data, at: nametableLayout.map(address))
            default:
                break
        }
    }
}
