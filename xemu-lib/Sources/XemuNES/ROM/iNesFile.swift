import Foundation
import XemuFoundation
import XemuCore

public struct iNesFile: RomFile {
    
    /// ROM image format version
    public enum Version {
        
        /// Archaic iNES ROM image
        case iNesDeprecated

        /// iNES ROM image
        case iNes
        
        /// NES 2.0 ROM image
        case nes20
        
        init(_ value: UInt) {
            if value == 2 {
                self = .nes20
            } else if value == 0 {
                self = .iNes
            } else {
                self = .iNesDeprecated
            }
        }
    }
    
    public static let fileExtensions: [String] = ["nes"]
    public static let magic: [u8] = [0x4E, 0x45, 0x53, 0x1A]  // NES\x1A
    
    public let version: Version
    public let consoleType: ConsoleType
    public let mapper: MapperType

    public let prgCount: u8
    public var chrCount: u8
    
    public var prgRom: Data
    public var chrRom: Data

    public let mirroringType: MirroringType
    
    /// "Battery" and other non-volatile memory
    public let hasBattery: Bool
    
    /// 512-byte Trainer present between Header and PRG-ROM data
    public let hasTrainer: Bool
    
    /// Expansion Port Sound Module
    public let hasEPSM: Bool
    
    /// Input Type
    public let inputType: InputType
    
    // Program ROM size in bytes
    public let prgRomSize: Int
    
    // Character ROM size in bytes
    public let chrRomSize: Int

    /// Volatile prg ram, also known as work ram
    public let prgRamSize: Int?
    
    /// Volatile chr ram
    public let chrRamSize: Int?
    
    /// Non-volatile prg ram also known as save ram
    public let prgPersistentRamSize: Int?
    
    /// Non-volatile chr ram, some mapper have battery backed chr ram
    public let chrPersistentRamSize: Int?

    public init(_ data: Data) throws(XemuError) {
        let d = BitIterator(data: data)
        
        let magic = try d.takeByte(4)
        
        guard iNesFile.magic == magic else {
            throw .fileFormatError
        }
        
        prgCount = try d.takeByte()
        chrCount = try d.takeByte()
        
        let flag6 = try d.takeByte()
        let flag7 = try d.takeByte()
        
        hasBattery = flag6 & 0x02 == 0x02
        hasTrainer = flag6 & 0x04 == 0x04
        
        mirroringType = if Bool(flag6 & 0x08) {
            .fourScreens
        } else {
            Bool(flag6 & 0x01) ? .vertical : .horizontal
        }
        
        version = if flag7 & 0x0c == 0x08 {
            .nes20
        } else if flag7 & 0x0c == 0x00 {
            .iNes
        } else {
            .iNesDeprecated
        }
        
        switch version {
            case .iNesDeprecated:
                d.advanceByte(by: 8)
                
                guard let mapper = MapperType(rawValue: u16(flag6 >> 4)) else {
                    throw .notImplemented
                }
                
                self.mapper = mapper
                self.hasEPSM = false
                self.inputType = .unspecified
                self.consoleType = .unknown

                let prgCount = self.prgCount == 0 ? 256 : Int(self.prgCount)
                self.prgRomSize = prgCount * 0x4000
                self.chrRomSize = Int(chrCount) * 0x2000
                
                self.prgRamSize = nil
                self.chrRamSize = nil
                self.prgPersistentRamSize = nil
                self.chrPersistentRamSize = nil
            case .iNes:
                let flag8 = try d.takeByte()
                let flag9 = try d.takeByte()
                let flag10 = try d.takeByte()
                d.advanceByte(by: 5)
                
                guard let mapper = MapperType(rawValue: u16((flag7 & 0xf0) | (flag6 >> 4))) else {
                    throw .notImplemented
                }
                
                self.mapper = mapper
                self.hasEPSM = false
                self.inputType = .unspecified
                
                consoleType = if Bool(flag7 & 0x01) {
                    .vsSystem
                } else if Bool(flag7 & 0x02) {
                    .playchoice
                } else {
                    Bool(flag9 & 0x01) ? .nesPAL : .unknown
                }
                
                let prgCount = self.prgCount == 0 ? 256 : Int(self.prgCount)
                self.prgRomSize = prgCount * 0x4000
                self.chrRomSize = Int(chrCount) * 0x2000
                
                self.prgRamSize = nil
                self.chrRamSize = nil
                self.prgPersistentRamSize = nil
                self.chrPersistentRamSize = nil
            case .nes20:
                let flag8 = try d.takeByte()
                let flag9 = try d.takeByte()
                let flag10 = try d.takeByte()
                let flag11 = try d.takeByte()
                let flag12 = try d.takeByte()
                let flag13 = try d.takeByte()
                let flag14 = try d.takeByte()
                let flag15 = try d.takeByte()
                
                guard let mapper = MapperType(rawValue: (u16(flag8 & 0x0f) << 8) | u16((flag7 & 0xf0) | (flag6 >> 4))) else {
                    throw .notImplemented
                }
                
                self.mapper = mapper
                self.hasEPSM = flag7 & 0x03 == 0x03 && flag13 & 0x0f == 0x04
                self.inputType = InputType(rawValue: flag15) ?? .unspecified
                
                let nes: () -> ConsoleType = {
                    switch flag12 & 0x03 {
                        case 0:
                            .nesNTSC
                        case 1:
                            .nesPAL
                        case 2:
                            .nesNTSC
                        case 3:
                            .dendy
                        default:
                            .unknown
                    }
                }
                
                consoleType = switch flag7 & 0x03 {
                    case 0:
                        nes()
                    case 1:
                        .vsSystem
                    case 2:
                        .playchoice
                    case 3:
                        switch flag13 & 0x0f {
                            case 0:
                                nes()
                            case 1:
                                .vsSystem
                            case 2:
                                .playchoice
                            case 4:
                                nes()
                            case 0xc:
                                .famicomNetworkSystem
                            default:
                                .unknown
                        }
                    default:
                        .unknown
                }
                
                self.prgRomSize = getRomSize(
                    value: flag9 & 0x0f,
                    bankCount: prgCount,
                    bankSize: 0x4000
                )
                
                self.chrRomSize = getRomSize(
                    value: (flag9 & 0xf0) >> 4,
                    bankCount: chrCount,
                    bankSize: 0x2000
                )

                self.prgRamSize = getRamSize(value: flag10 & 0x0f)
                self.chrRamSize = getRamSize(value: flag11 & 0x0f)

                self.prgPersistentRamSize = getRamSize(value: (flag10 & 0xf0) >> 4)
                self.chrPersistentRamSize = getRamSize(value: (flag11 & 0xf0) >> 4)
                
                // TODO: add vs system stuff here
        }
        
        if hasTrainer {
            d.advanceByte(by: 512)
        }
        
        prgRom = data.subdata(in: d.index..<(d.index + prgRomSize))
        d.advanceByte(by: prgRomSize)
        
        // TODO: see if I need to pad prgRom when it is too small
        
        chrRom = chrRomSize != 0 ? data.subdata(in: d.index..<(d.index + chrRomSize)) : Data()
    }
}

private func getSize(exponent: u8, multiplier: u8) -> Int {
    let exponent = min(exponent, 60)
    let multiplier = (multiplier << 1) + 1
    
    let size = u64(multiplier) * (u64(1) << u64(exponent))
    
    return Int(truncatingIfNeeded: size)
}

private func getRomSize(value: u8, bankCount: u8, bankSize: u16) -> Int {
    if value == 0x0f {
        getSize(exponent: bankCount >> 2, multiplier: bankCount & 0x03)
    } else {
        Int((u16(value) << 8) | u16(bankCount)) * Int(bankSize)
    }
}

private func getRamSize(value: u8) -> Int {
    value == 0 ? 0 : Int(128 * powf(2, Float(value - 1)))
}
