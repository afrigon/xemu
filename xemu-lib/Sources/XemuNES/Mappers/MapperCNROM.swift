import Foundation
import XemuFoundation

final class MapperCNROM: Mapper {
    var type: MapperType = .cnrom
    
    let pgrrom: Memory
    let chrrom: Memory
    var sram: Memory
    
    let vram: Memory
    let nametableLayout: NametableLayout

    var chrbank: u8 = 0

    required init(from iNes: iNesFile, saveData: Data) {
        pgrrom = .init(iNes.pgrrom)
        chrrom = .init(iNes.chrrom)
        sram = .init(saveData)
        vram = .init(.init(repeating: 0, count: 0x800))
        nametableLayout = iNes.nametableLayout
    }
    
    func cpuDebugRead(at address: u16) -> u8? {
        cpuRead(at: address)
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
                chrbank = data & 0b0000_0011
            default:
                break
        }
    }
    
    func ppuDebugRead(at address: u16) -> u8? {
        ppuRead(at: address)
    }
    
    func ppuRead(at address: u16) -> u8? {
        switch address {
            case 0x0000..<0x2000:
                chrrom.bankedRead(at: address, bankIndex: Int(chrbank), bankSize: 0x2000)
            case 0x2000..<0x4000:
                vram.read(at: nametableLayout.map(address))
            default:
                nil
        }
    }
    
    func ppuWrite(_ data: u8, at address: u16) {
        switch address {
            case 0x0000..<0x2000:
                chrrom.bankedWrite(data, at: address, bankIndex: Int(chrbank), bankSize: 0x2000)
            case 0x2000..<0x4000:
                vram.write(data, at: nametableLayout.map(address))
            default:
                break
        }
    }
}
