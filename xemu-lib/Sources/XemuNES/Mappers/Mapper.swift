import Foundation
import XemuFoundation

class Mapper: Codable {
    weak var bus: Bus!
    
    var prgRom: [u8] = []
    var chrRom: [u8] = []

    var prgRam: [u8] = []
    var prgPersistentRam: [u8] = []
    var chrRam: [u8] = []
    var nametableRam: [u8] = []

    var prgRomSize: Int = 0
    var prgRamSize: Int = 0
    var prgPersistentRamSize: Int = 0
    
    var chrRomSize: Int = 0
    var chrRamSize: Int = 0
    var nametableSize: Int = 0
    var nametableCount: Int = 0

    let hasBattery: Bool
    let hasChrBattery: Bool
    var mirroring: MirroringType
    
    var cpuPages: [CPUPage] = .init(repeating: .unmapped, count: 0x100)
    var ppuPages: [PPUPage] = .init(repeating: .unmapped, count: 0x100)
    var isRegister: [Bool] = .init(repeating: false, count: 0x10000)

    var type: MapperType {
        fatalError("Must override Mapper.type")
    }
    
    var saveData: [u8] {
        var save = GameSave()
        
        if hasBattery && prgPersistentRamSize > 0 {
            save.prg = .init(prgPersistentRam)
        }
        
        if hasChrBattery && chrRamSize > 0 {
            save.chr = .init(chrRam)
        }

        guard save.prg != nil || save.chr != nil else {
            return []
        }
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        do {
            let data = try encoder.encode(save)
            
            return .init(data)
        } catch {
            return []
        }
    }
    
    init(from rom: iNesFile, saveData: Data? = nil) {
        prgRom = .init(rom.prgRom)
        chrRom = .init(rom.chrRom)
        
        prgRomSize = rom.prgRomSize
        chrRomSize = rom.chrRomSize
        
        hasBattery = rom.hasBattery
        hasChrBattery = (rom.chrPersistentRamSize ?? 0) > 0
        mirroring = rom.mirroringType

        if let prgPersistentRamSize = rom.prgPersistentRamSize {
            self.prgPersistentRamSize = prgPersistentRamSize
        } else {
            self.prgPersistentRamSize = rom.hasBattery ? self.getprgPersistentRamSize() : 0
        }
        
        if let prgRamSize = rom.prgRamSize {
            self.prgRamSize = prgRamSize
        } else {
            self.prgRamSize = rom.hasBattery ? 0 : self.getprgRamSize()
        }
        
        prgPersistentRam = .init(repeating: 0, count: prgPersistentRamSize)
        prgRam = .init(repeating: 0, count: prgRamSize)
        
        nametableCount = getNametableCount()
        
        if nametableCount == 0 {
            nametableCount = rom.mirroringType == .fourScreens ? 4 : 2
        }
        
        nametableSize = nametableCount * getNametableSize()
        nametableRam = .init(repeating: 0, count: nametableSize)
        
        if rom.chrRomSize == 0 {
            chrInitialize(size: rom.chrRamSize)
        } else if let chrRamSize = rom.chrRamSize {
            chrInitialize(size: chrRamSize)
        } else {
            chrInitialize()
        }
        
        // TODO: trainer data relevant here ?
        
        if rom.hasBattery && prgPersistentRamSize > 0 {
            mapCPU(0x6000...0x7fff, to: .prgPersistentRam, 0)
        } else {
            mapCPU(0x6000...0x7fff, to: .prgRam, 0)
        }
        
        setMirroring(rom.mirroringType)
        
        if let saveData {
            let decoder = PropertyListDecoder()
            
            do {
                let data = try decoder.decode(GameSave.self, from: saveData)
                
                if let prgData = data.prg {
                    prgPersistentRam = .init(prgData)
                }
                
                if let chrData = data.chr {
                    chrRam = .init(chrData)
                }
            } catch {
                // do nothing and run without save data
            }
        }

        // TODO: espm stuff
        
        mapRegister(getRegisterRange(), true)
        
        initialize()
    }
    
    func mapCPU(
        _ range: ClosedRange<u16>,
        to region: CPURegion,
        _ page: Int,
        _ access: MemoryAccessType = .readWrite
    ) {
        guard range.lowerBound & 0xff == 0 && range.upperBound & 0xff == 0xff else {
            print("Mapper: failed to map cpu with bounds: \(range)")
            return
        }
        
        let start = Int(range.lowerBound >> 8)
        let end = Int(range.upperBound >> 8)
        
        // TODO: fix mapCPU and mapPPU
        let bufferSize = switch region {
            case .prgRom:
                prgRomSize
            case .prgRam:
                prgRamSize
            case .prgPersistentRam:
                prgPersistentRamSize
        }
        
        let pageSize = if region == .prgRom {
            min(bufferSize, getPrgPageSize())
        } else {
            bufferSize
        }
        
        guard bufferSize > 0, pageSize > 0 else {
            print("Mapper: tried to map an empty region: \(region)")
            return
        }
        
        let pageCount = max(bufferSize / pageSize, 1)
        
        let bank = if page < 0 {
            (page % pageCount + pageCount) % pageCount
        } else {
            page % pageCount
        }
        
        var offset: Int = bank * pageSize
        
        for index in start...end {
            cpuPages[index] = .init(
                region: region,
                base: offset,
                access: access
            )
            
            offset += 0x100
            
            if offset >= bufferSize {
                offset %= bufferSize
            }
        }
    }
    
    func mapPPU(
        _ range: ClosedRange<u16>,
        to region: PPURegion,
        _ page: Int,
        _ access: MemoryAccessType = .readWrite
    ) {
        guard range.lowerBound & 0xff == 0 && range.upperBound & 0xff == 0xff else {
            print("Mapper: failed to map ppu with bounds: \(range)")
            return
        }
        
        let start = Int(range.lowerBound >> 8)
        let end = Int(range.upperBound >> 8)
        
        let bufferSize = switch region {
            case .automatic:
                if chrRomSize > 0 {
                    chrRomSize
                } else {
                    chrRamSize
                }
            case .chrRom:
                chrRomSize
            case .chrRam:
                chrRamSize
            case .nametableRam:
                nametableSize
        }
        
        let pageSize = switch region {
            case .automatic:
                if chrRomSize > 0 {
                    min(chrRomSize, getChrPageSize())
                } else {
                    chrRamSize
                }
            case .chrRom:
                min(chrRomSize, getChrPageSize())
            case .chrRam:
                chrRamSize
            case .nametableRam:
                min(nametableSize, getNametableSize())
        }
        
        guard bufferSize > 0, pageSize > 0 else {
            print("Mapper: tried to map an empty region: \(region)")
            return
        }
        
        let pageCount = max(bufferSize / pageSize, 1)
        
        let bank = if page < 0 {
            (page % pageCount + pageCount) % pageCount
        } else {
            page % pageCount
        }
        
        var offset: Int = bank * pageSize
        
        for index in start...end {
            ppuPages[index] = .init(
                region: region,
                base: offset,
                access: access
            )
            
            offset += 0x100
            
            if offset >= bufferSize {
                offset %= bufferSize
            }
        }
    }
    
    func unmapCPU(_ range: ClosedRange<u16>) {
        guard range.lowerBound & 0xff == 0 && range.upperBound & 0xff == 0xff else {
            print("Mapper: failed to unmap ppu with bounds: \(range)")
            return
        }
        
        let start = Int(range.lowerBound >> 8)
        let end = Int(range.upperBound >> 8)
        
        for index in start...end {
            cpuPages[index] = .unmapped
        }
    }
    
    func unmapPPU(_ range: ClosedRange<u16>) {
        guard range.lowerBound & 0xff == 0 && range.upperBound & 0xff == 0xff else {
            print("Mapper: failed to unmap ppu with bounds: \(range)")
            return
        }
        
        let start = Int(range.lowerBound >> 8)
        let end = Int(range.upperBound >> 8)
        
        for index in start...end {
            ppuPages[index] = .unmapped
        }
    }
    
    func mapRegister(
        _ range: ClosedRange<u16>,
        _ isRegister: Bool,
        _ access: MemoryAccessType = .readWrite
    ) {
        for i in range {
            self.isRegister[Int(i)] = isRegister
        }
    }
    
    func setMirroring(_ type: MirroringType) {
        mirroring = type
        
        switch mirroring {
            case .vertical:
                setNametables(0, 1, 0, 1)
            case .horizontal:
                setNametables(0, 0, 1, 1)
            case .fourScreens:
                setNametables(0, 1, 2, 3)
            case .onlyA:
                setNametables(0, 0, 0, 0)
            case .onlyB:
                setNametables(1, 1, 1, 1)
        }
    }

    func setNametables(
        _ a: Int,
        _ b: Int,
        _ c: Int,
        _ d: Int
    ) {
        setNametable(0, a)
        setNametable(1, b)
        setNametable(2, c)
        setNametable(3, d)
    }
    
    func setNametable(
        _ index: Int,
        _ nametable: Int
    ) {
        let a = 0x2000 + u16(index) * 0x400
        let b = 0x2000 + (u16(index) + 1) * 0x400 - 1
        
        mapPPU(
            a...b,
            to: .nametableRam,
            nametable,
            .readWrite
        )

        mapPPU(
            (a + 0x1000)...(b + 0x1000),
            to: .nametableRam,
            nametable,
            .readWrite
        )
    }

    func getprgRamSize() -> Int {
        0x2000
    }
    
    func getprgPersistentRamSize() -> Int {
        0x2000
    }
    
    func getChrRamSize() -> Int {
        0x0000
    }
    
    func getNametableCount() -> Int {
        0
    }
    
    func getNametableSize() -> Int {
        0x0400
    }
    
    func getPrgPageSize() -> Int {
        0x0000
    }
    
    func getChrPageSize() -> Int {
        0x0000
    }
    
    func getChrRamPageSize() -> Int {
        getChrPageSize()
    }
    
    func getPrgRamPageSize() -> Int {
        0x2000
    }
    
    func getPrgPersistentRamPageSize() -> Int {
        0x2000
    }

    func getRegisterRange() -> ClosedRange<u16> {
        0x8000...0xffff
    }
    
    func allowRegisterRead() -> Bool {
        false
    }
    
    func initialize() {  }
    
    func chrInitialize(size: Int? = nil) {
        if let size {
            chrRamSize = size
            chrRam = .init(repeating: 0, count: chrRamSize)
        } else {
            var size = getChrRamSize()
            
            if size == 0 {
                size = 0x2000
            }
            
            chrRamSize = size
            chrRam = .init(repeating: 0, count: chrRamSize)
        }
    }

    func prgSelect(for slot: Int, page: Int, _ region: CPURegion = .prgRom) {
        if prgRomSize < 0x8000 && getPrgPageSize() > prgRomSize {
            for i in 0..<(0x8000 / prgRomSize) {
                let start = u16(0x8000 + i * prgRomSize)
                let end = start + (u16(prgRomSize) - 1)
                
                mapCPU(start...end, to: region, 0)
            }
        } else {
            let pageSize = min(getPrgPageSize(), prgRomSize)
            let start = u16(0x8000 + slot * pageSize)
            let end = start + (u16(pageSize) &- 1)
            
            mapCPU(start...end, to: region, page)
        }
    }
    
    func chrSelect(for slot: Int, page: Int, _ region: PPURegion = .automatic) {
        let pageSize = switch region {
            case .nametableRam:
                getNametableSize()
            case .chrRam:
                min(chrRamSize, getChrRamPageSize())
            case .chrRom:
                min(chrRomSize, getChrPageSize())
            case .automatic:
                chrRomSize > 0 ?
                min(chrRomSize, getChrPageSize()) :
                min(chrRamSize, getChrRamPageSize())
        }
        
        let start = u16(slot * pageSize)
        let end = start + (u16(pageSize) &- 1)
        
        mapPPU(start...end, to: region, page)
    }

    func registerWrite(_ data: u8, at address: u16) {
        
    }
    
    func registerRead(at address: u16) -> u8 {
        // TODO: return open bus
        0
    }

    func cpuDebugRead(at address: u16) -> u8? {
        cpuRead(at: address)
    }
    
    func cpuRead(at address: u16) -> u8? {
        if allowRegisterRead() && isRegister[Int(address)] {
            return registerRead(at: address)
        }
        
        let page = cpuPages[Int(address >> 8)]
        
        guard page.access.contains(.read) else {
            return nil
        }
        
        guard let region = page.region else {
            return nil
        }
        
        let index = page.base + Int(address & 0xff)
        
        switch region {
            case .prgRom:
                return prgRom[index]
            case .prgRam:
                return prgRam[index]
            case .prgPersistentRam:
                return prgPersistentRam[index]
        }
    }
    
    func cpuWrite(_ data: u8, at address: u16) {
        if isRegister[Int(address)] {
            // TODO: handle bus conflict
            return registerWrite(data, at: address)
        }
        
        let page = cpuPages[Int(address >> 8)]
        
        guard page.access.contains(.write) else {
            return
        }
        
        guard let region = page.region else {
            return
        }
        
        let index = page.base + Int(address & 0xff)
        
        switch region {
            case .prgRom:
                prgRom[index] = data
            case .prgRam:
                prgRam[index] = data
            case .prgPersistentRam:
                prgPersistentRam[index] = data
        }
    }
    
    func ppuDebugRead(at address: u16) -> u8 {
        ppuRead(at: address)
    }
    
    func ppuRead(at address: u16) -> u8 {
        let page = ppuPages[Int(address >> 8)]
        
        guard page.access.contains(.read) else {
            return u8(truncatingIfNeeded: address)
        }
        
        guard let region = page.region else {
            return u8(truncatingIfNeeded: address)
        }
        
        let index = page.base + Int(address & 0xff)
        
        return switch region {
            case .automatic:
                if chrRomSize > 0 {
                    chrRom[index]
                } else {
                    chrRam[index]
                }
            case .chrRom:
                chrRom[index]
            case .chrRam:
                chrRam[index]
            case .nametableRam:
                nametableRam[index]
        }
    }
    
    func ppuWrite(_ data: u8, at address: u16) {
        let page = ppuPages[Int(address >> 8)]
        
        guard page.access.contains(.write) else {
            return
        }
        
        guard let region = page.region else {
            return
        }
        
        let index = page.base + Int(address & 0xff)
        
        switch region {
            case .automatic:
                if chrRomSize > 0 {
                    chrRom[index] = data
                } else {
                    chrRam[index] = data
                }
            case .chrRom:
                chrRom[index] = data
            case .chrRam:
                chrRam[index] = data
            case .nametableRam:
                nametableRam[index] = data
        }
    }
    
    static func create(rom: iNesFile, saveData: Data?) -> Mapper {
        let factory: (iNesFile, Data?) -> Mapper = switch rom.mapper {
            case .nrom:
                MapperNROM.init
            case .mmc1:
                MapperMMC1.init
            case .unrom:
                MapperUNROM.init
            case .cnrom:
                MapperCNROM.init
            case .axrom:
                MapperAXROM.init
            case .cprom:
                MapperCPROM.init
            case .gxrom:
                MapperGxROM.init
        }
        
        return factory(rom, saveData)
    }
    
    enum CodingKeys: CodingKey {
        case prgRom
        case chrRom
        case prgRam
        case prgPersistentRam
        case chrRam
        case nametableRam
        case prgRomSize
        case prgRamSize
        case prgPersistentRamSize
        case chrRomSize
        case chrRamSize
        case nametableSize
        case nametableCount
        case hasBattery
        case hasChrBattery
        case mirroring
        case cpuPages
        case ppuPages
        case isRegister
    }
}
