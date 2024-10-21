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
    
    /// Hard-wired nametable layout
    enum NametableArrangement {
        
        /// Vertical arrangement ("mirrored horizontally") or mapper-controlled
        case vertical
        
        /// Horizontal arrangement ("mirrored vertically")
        case horizontal
        
        /// Alternative Nametables
        /// https://www.nesdev.org/wiki/NES_2.0#Nametable_layout
        case other
        
        init(_ value: Bool, alternative: Bool) {
            if alternative {
                self = .other
            } else {
                if value {
                    self = .horizontal
                } else {
                    self = .vertical
                }
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

    public static var fileExtensions: [String] = ["nes"]
    public static var magic: [UInt8] = [0x4E, 0x45, 0x53, 0x1A]  // NES\x1A
    
    public static let pgrRomUnitSize = 0x4000
    public static let chrRomUnitSize = 0x2000

    let pgrRomSize: UInt8
    let chrRomSize: UInt8
    
    let pgrRom: Data
    let chrRom: Data

    // Flag 6
    
    /// Hard-wired nametable layout
    let nametableArrangement: NametableArrangement
    
    /// "Battery" and other non-volatile memory
    let hasBattery: Bool
    
    /// 512-byte Trainer present between Header and PRG-ROM data
    let hasTrainer: Bool
    
    // Flag 7
    let consoleType: ConsoleType
    let version: Version
    
    let mapper: MapperType

    // Flag 8

    @MainActor
    public init(_ data: Data) throws(XemuError) {
        let d = BitIterator(data: data)
        
        let magic = try d.takeByte(4)
        
        guard iNesFile.magic == magic else {
            throw .fileFormatError
        }
        
        pgrRomSize = try d.takeByte()
        chrRomSize = try d.takeByte()
        
        // Flag 6
        let mapperLo = try d.takeBit(4)
        let isUsingAlternativeNametableLayout = try d.takeBit(1) != 0
        hasTrainer = try d.takeBit(1) != 0
        hasBattery = try d.takeBit(1) != 0
        nametableArrangement = NametableArrangement(try d.takeBit(1) != 0, alternative: isUsingAlternativeNametableLayout)
        
        // Flag 7
        let mapperHi = try d.takeBit(4)
        let consoleType = try d.takeBit(2)
        version = Version(try d.takeBit(2))
        
        switch version {
            case .iNes:
                self.consoleType = ConsoleType(rawValue: consoleType)!
                
                guard let mapper = MapperType(rawValue: UInt16(mapperHi) << 4 | UInt16(mapperLo)) else {
                    throw .notImplemented
                }
                
                self.mapper = mapper
                
                // TODO: double check past this
                // Flag 8
                let pgrRamSize = try d.takeByte()
                
                // Flag 9
                d.advanceBit(by: 7)
                let tvSystem = try d.takeBit(1) != 0
                
                // Flag 10
                d.advanceByte(by: 1)

                d.advanceByte(by: 5)
                
                if hasTrainer {
                    d.advanceByte(by: 512)
                }
                
                let pgrRomStart = d.index
                let pgrRomCount = iNesFile.pgrRomUnitSize * Int(pgrRomSize)
                d.advanceByte(by: pgrRomCount)
                let pgrRomEnd = d.index
                pgrRom = data.subdata(in: pgrRomStart..<pgrRomEnd)
                
                let chrRomStart = d.index
                let chrRomCount = iNesFile.chrRomUnitSize * Int(chrRomSize)
                d.advanceByte(by: chrRomCount)
                let chrRomEnd = d.index
                chrRom = data.subdata(in: chrRomStart..<chrRomEnd)
            case .nes20:
                
                // Flag 8
                let submapper = try d.takeBit(4)
                let mapperVeryHi = try d.takeBit(4)
                
                let mapper = UInt16(mapperVeryHi) << 8 | UInt16(mapperHi) << 4 | UInt16(mapperLo)
                
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
