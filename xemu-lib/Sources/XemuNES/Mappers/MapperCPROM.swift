import Foundation
import XemuFoundation

final class MapperCPROM: Mapper {
    override var type: MapperType {
        .cprom
    }
    
    override func getPrgPageSize() -> Int {
        0x8000
    }
    
    override func getChrPageSize() -> Int {
        0x1000
    }
    
    override func getChrRamSize() -> Int {
        0x4000
    }
    
    override func initialize() {
        super.initialize()
        
        prgSelect(for: 0, page: 0)
        chrSelect(for: 0, page: 0)
        setMirroring(.vertical)
    }
    
    override func registerWrite(_ data: u8, at address: u16) {
        if address >= 0x8000 {
            chrSelect(for: 1, page: Int(data & 0x03))
        }
    }
}
