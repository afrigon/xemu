import Foundation
import XemuFoundation

final class MapperUNROM: Mapper {
    override var type: MapperType {
        .unrom
    }
    
    override func getPrgPageSize() -> Int {
        0x4000
    }
    
    override func getChrPageSize() -> Int {
        0x2000
    }

    override func initialize() {
        super.initialize()
        
        prgSelect(for: 0, page: 0)
        prgSelect(for: 1, page: -1)
        
        chrSelect(for: 0, page: 0)
    }
    
    override func registerWrite(_ data: u8, at address: u16) {
        super.registerWrite(data, at: address)
        
        prgSelect(for: 0, page: Int(data))
    }
}
