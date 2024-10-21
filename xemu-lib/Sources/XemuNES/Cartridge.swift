public class Cartridge: BusComponent {
    let mapper: Mapper
    
    init(as file: iNesFile) {
        mapper = Mapper.create(type: file.mapper)
    }
    
    func read(at address: UInt16) -> UInt8 {
        <#code#>
    }
    
    func write(_ data: UInt8, at address: UInt16) {
        <#code#>
    }
}
