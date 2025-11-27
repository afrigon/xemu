import Foundation
import XemuFoundation

final class MapperAXROM: Mapper {
    override var type: MapperType {
        .axrom
    }
    
    override func getPrgPageSize() -> Int {
        0x8000
    }
    
    override func getChrPageSize() -> Int {
        0x2000
    }
    
    override func initialize() {
        super.initialize()
        
        chrSelect(for: 0, page: 0)
        registerWrite(0, at: 0)
    }
    
    override func registerWrite(_ data: u8, at address: u16) {
        prgSelect(for: 0, page: Int(data & 0x0f))
        setMirroring((data & 0x10) == 0x10 ? .onlyB : .onlyA)
    }
}
