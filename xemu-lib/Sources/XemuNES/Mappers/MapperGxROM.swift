import Foundation
import XemuFoundation

final class MapperGxROM: Mapper {
    override var type: MapperType {
        .gxrom
    }
    
    override func getPrgPageSize() -> Int {
        0x8000
    }
    
    override func getChrPageSize() -> Int {
        0x2000
    }
    
    override func initialize() {
        super.initialize()
        
        prgSelect(for: 0, page: 0)
        chrSelect(for: 0, page: 0)
    }
    
    override func registerWrite(_ data: u8, at address: u16) {
        prgSelect(for: 0, page: Int(data >> 4) & 0x03)
        chrSelect(for: 0, page: Int(data & 0x03))
    }
}
