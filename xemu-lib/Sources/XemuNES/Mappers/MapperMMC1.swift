import Foundation
import XemuFoundation

/// https://www.nesdev.org/wiki/MMC1
final class MapperMMC1: Mapper {
    override var type: MapperType {
        .mmc1
    }
    
    var lastWrite: u64 = 0
    
    override func getPrgPageSize() -> Int {
        0x4000
    }
    
    override func getChrPageSize() -> Int {
        0x1000
    }
    
    override func initialize() {
        super.initialize()
        
        handleRegisterWrite(0x0c, at: 0x8000)
        handleRegisterWrite(0x00, at: 0xA000)
        handleRegisterWrite(0x00, at: 0xC000)
        handleRegisterWrite(0x00, at: 0xE000)
    }
    
    override func registerWrite(_ data: u8, at address: u16) {
        super.registerWrite(data, at: address)
        
        let cycle = bus.cycles
        
        if Bool(data & 0x80) || cycle - lastWrite >= 2 {
            // TODO: process bit write
        }
        
        lastWrite = cycle
    }
    
    private func handleRegisterWrite(_ data: u8, at address: u16) {
        
    }
    
    private func update() {
        
    }
}
