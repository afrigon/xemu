import Foundation
import XemuFoundation
import XemuCore

public struct iNesFile: RomFile {
    
    /// ROM image format version
    enum Version {
        
        /// iNES ROM image
        case iNes
        
        /// NES 2.0 ROM image
        case nes20
        
        init(_ value: UInt) {
            if value == 2 {
                self = .nes20
            } else {
                self = .iNes
            }
        }
    }
    
    enum ConsoleType: UInt {
        
        /// Nintendo Entertainment System/Family Computer
        case nes = 0
        
        /// Nintendo Vs. System
        case vsSystem
        
        /// Nintendo Playchoice 10
        case playchoice10
        
        /// Regular Famiclone, but with CPU that supports Decimal Mode
        case decimalModeFamiclone
        
        /// Regular NES/Famicom with EPSM module or plug-through cartridge
        case epsmNes
        
        /// V.R. Technology VT01 with red/cyan STN palette
        case vt1
        
        /// V.R. Technology VT02
        case vt2
        
        /// V.R. Technology VT03
        case vt3
        
        /// V.R. Technology VT09
        case vt9
        
        /// V.R. Technology VT32
        case vt32
        
        /// V.R. Technology VT369
        case vt369
        
        /// UMC UM6578
        case um6578
        
        /// Famicom Network System
        case famicomNetworkSystem
        
        /// Reserved console type
        case reservedA
        
        /// Reserved console type
        case reservedB
        
        /// Reserved console type
        case reservedC
    }

    public static let fileExtensions: [String] = ["nes"]
    public static let magic: [u8] = [0x4E, 0x45, 0x53, 0x1A]  // NES\x1A
    
    public static let pgrRomUnitSize = 0x4000
    public static let chrRomUnitSize = 0x2000

    public let wramSize: u8
    public let pgrromSize: u8
    public let chrromSize: u8

    public let pgrrom: Data
    public let chrrom: Data

    // Flag 6
    
    /// Hard-wired nametable layout
    let nametableLayout: NametableLayout
    
    /// "Battery" and other non-volatile memory
    let hasBattery: Bool
    
    /// 512-byte Trainer present between Header and PRG-ROM data
    let hasTrainer: Bool
    
    // Flag 7
    let consoleType: ConsoleType
    let version: Version
    
    let mapper: MapperType

    // Flag 8

    public init(_ data: Data) throws(XemuError) {
        let d = BitIterator(data: data)
        
        let magic = try d.takeByte(4)
        
        guard iNesFile.magic == magic else {
            throw .fileFormatError
        }
        
        pgrromSize = try d.takeByte()
        chrromSize = try d.takeByte()
        
        // Flag 6
        let mapperLo = try d.takeBit(4)
        let isUsingAlternativeNametableLayout = try d.takeBit(1) != 0
        hasTrainer = try d.takeBit(1) != 0
        hasBattery = try d.takeBit(1) != 0
        nametableLayout = NametableLayout(try d.takeBit(1) != 0, alternative: isUsingAlternativeNametableLayout)
        
        // Flag 7
        let mapperHi = try d.takeBit(4)
        let consoleType = try d.takeBit(2)
        version = Version(try d.takeBit(2))
        
        switch version {
            case .iNes:
                self.consoleType = ConsoleType(rawValue: consoleType)!
                
                guard let mapper = MapperType(rawValue: u16(mapperHi) << 4 | u16(mapperLo)) else {
                    throw .notImplemented
                }
                
                self.mapper = mapper
                
                // TODO: double check past this
                // Flag 8
                wramSize = try d.takeByte()
                
                // Flag 9
                d.advanceBit(by: 7)
                let tvSystem = try d.takeBit(1) != 0
                
                // Flag 10
                d.advanceByte(by: 1)

                d.advanceByte(by: 5)
                
                if hasTrainer {
                    d.advanceByte(by: 512)
                }
                
                let pgrromStart = d.index
                let pgrromCount = iNesFile.pgrRomUnitSize * Int(pgrromSize)
                d.advanceByte(by: pgrromCount)
                let pgrromEnd = d.index
                pgrrom = data.subdata(in: pgrromStart..<pgrromEnd)
                
                let chrromStart = d.index
                let chrromCount = iNesFile.chrRomUnitSize * Int(chrromSize)
                d.advanceByte(by: chrromCount)
                let chrromEnd = d.index
                chrrom = data.subdata(in: chrromStart..<chrromEnd)
            case .nes20:
                
                // Flag 8
                let submapper = try d.takeBit(4)
                let mapperVeryHi = try d.takeBit(4)
                
                guard let mapper = MapperType(rawValue: u16(mapperVeryHi) << 8 | u16(mapperHi) << 4 | u16(mapperLo)) else {
                    throw .notImplemented
                }
                
                self.mapper = mapper

                // Flag 9
                // Flag 10
                // Flag 11
                // Flag 12
                // Flag 13
                
                // if using extended console type
                if consoleType & 3 != 0 {
                    d.advanceBit(by: 4)
                    self.consoleType = ConsoleType(rawValue: try d.takeBit(4))!
                } else {
                    self.consoleType = ConsoleType(rawValue: consoleType)!
                }
                
                // TODO: finish implementing 2.0
                throw .notImplemented
        }
    }
}
