import Foundation
import XemuFoundation

/// https://www.nesdev.org/wiki/MMC1
class MapperMMC1: Mapper {
    var type: MapperType = .mmc1
    
    let pgrrom: Memory
    let chrrom: Memory
    let sram: Memory
    
    let vram: Memory
    var nametableLayout: NametableLayout

    /// Consecutive-cycle writes
    ///
    /// When the serial port is written to on consecutive cycles, it ignores
    /// every write after the first. In practice, this only happens when the
    /// CPU executes read-modify-write instructions, which first write the
    /// original value before writing the modified one on the next cycle.
    ///
    /// This restriction only applies to the data being written on bit 0;
    /// the bit 7 reset is never ignored.
    ///
    /// This write-ignore behavior appears to be intentional and is believed to
    /// ignore all consecutive write cycles after the first even if that first
    /// write does not target the serial port.
    var writeEnabled = true

    /// Shift Register
    ///
    /// Bit 0 of load register gets pushed in shift register from the left.
    /// When Bit 2 is 1, process the shift register into one of the internal
    /// registers.
    ///
    /// The address of the last write to load register selects the internal register
    ///
    /// ```
    /// 0x8000-0x9FFF -> control
    /// 0xA000-0xBFFF -> CHR Bank 0
    /// 0xC000-0xDFFF -> CHR Bank 1
    /// 0xE000-0xFFFF -> PGR Bank
    /// ```
    ///
    var shift: u8 = 0b1000_0000

    /// Control Register (Internal, 0x8000-0x9FFF)
    ///
    /// ```
    /// 4bit0
    /// -----
    /// CPPMM
    /// |||||
    /// |||++- Nametable arrangement: (0: one-screen, lower bank; 1: one-screen, upper bank;
    /// |||               2: horizontal arrangement ("vertical mirroring", PPU A10);
    /// |||               3: vertical arrangement ("horizontal mirroring", PPU A11) )
    /// |++--- PRG ROM bank mode (0, 1: switch 32 KB at $8000, ignoring low bit of bank number;
    /// |                         2: fix first bank at $8000 and switch 16 KB bank at $C000;
    /// |                         3: fix last bank at $C000 and switch 16 KB bank at $8000)
    /// +----- CHR ROM bank mode (0: switch 8 KB at a time; 1: switch two separate 4 KB banks)
    /// ```
    var control: u8 = 0b01100
    
    var chrbank0: u8 = 0
    var chrbank1: u8 = 0
    var pgrbank: u8 = 0
    var srambank: u8 = 0
    var sramEnabled: Bool = true

    init(pgrrom: Memory, chrrom: Memory, sram: Memory) {
        self.pgrrom = pgrrom
        self.chrrom = chrrom
        self.sram = sram
        self.vram = .init(.init(repeating: 0, count: 0x800))
        self.nametableLayout = .horizontal
    }
    
    required init(from iNes: iNesFile, saveData: Data) {
        pgrrom = .init(iNes.pgrrom)
        chrrom = .init(iNes.chrrom)
//        sram = .init(saveData)
        sram = .init(.init(repeating: 0, count: 0x8000))
        vram = .init(.init(repeating: 0, count: 0x800))
        nametableLayout = iNes.nametableLayout
    }
    
    func cpuRead(at address: u16) -> u8? {
        writeEnabled = true
        
        switch address {
            case 0x6000..<0x8000:
                // TODO: banked read
                return sram.bankedRead(at: address - 0x6000, bankIndex: Int(srambank), bankSize: 0x2000)
            case 0x8000..<0xC000:
                guard !pgrrom.data.isEmpty else {
                    return nil
                }
                
                let mode = control >> 2 & 0b11
                switch mode {
                    case 0, 1:
                        return pgrrom.bankedRead(at: address - 0x8000, bankIndex: Int(pgrbank) & 0b1111_1110, bankSize: 0x4000)
                    case 2:
                        return pgrrom.bankedRead(at: address - 0x8000, bankIndex: 0, bankSize: 0x4000)
                    case 3:
                        return pgrrom.bankedRead(at: address - 0x8000, bankIndex: Int(pgrbank), bankSize: 0x4000)
                    default:
                        return nil
                }
            case 0xC000...0xFFFF:
                guard !pgrrom.data.isEmpty else {
                    return nil
                }

                let mode = control >> 2 & 0b11
                switch mode {
                    case 0, 1:
                        return pgrrom.bankedRead(at: address - 0x8000, bankIndex: Int(pgrbank) | 0b0000_0001, bankSize: 0x4000)
                    case 2:
                        return pgrrom.bankedRead(at: address - 0x8000, bankIndex: Int(pgrbank), bankSize: 0x4000)
                    case 3:
                        return pgrrom.bankedRead(at: address - 0x8000, bankIndex: 0xFF, bankSize: 0x4000)
                    default:
                        return nil
                }
            default:
                return nil
        }
    }
    
    func cpuWrite(_ data: u8, at address: u16) {
        switch address {
            case 0x6000..<0x8000:
                if sramEnabled {
                    sram.bankedWrite(data, at: address - 0x6000, bankIndex: Int(srambank), bankSize: 0x2000)
                }
            case 0x8000...0xFFFF:
                // bit 7 high triggers a reset
                if Bool(data & 0b1000_0000) {
                    shift = 0b1000_0000
                    control |= 0b01100
                } else {
                    guard writeEnabled else {
                        return
                    }
                    
                    shift = shift >> 1 | data << 7
                    
                    if Bool(shift & 0b0000_0100) {
                        let value = shift >> 3
                        
                        switch address & 0xE000 {
                            case 0x8000:
                                control = value
                                
                                nametableLayout = switch value & 0b11 {
                                    case 0b00: .oneScreenLower
                                    case 0b01: .oneScreenUpper
                                    case 0b10: .vertical
                                    case 0b11: .horizontal
                                    default: .horizontal
                                }
                            case 0xA000:
                                chrbank0 = value
                                srambank = value >> 2 & 0b11
                            case 0xC000:
                                chrbank1 = value
                                srambank = value >> 2 & 0b11
                            case 0xE000:
                                pgrbank = value & 0b0000_1111
                                sramEnabled = Bool(value & 0b0001_0000)
                            default:
                                break
                        }

                        shift = 0b1000_0000
                    }
                }
            default:
                break
        }
        
        writeEnabled = false
    }
    
    func ppuRead(at address: u16) -> u8? {
        switch address {
            case 0x0000...0x0FFF:
                if Bool(control & 0b0001_0000) {
                    chrrom.bankedRead(at: address, bankIndex: Int(chrbank0), bankSize: 0x1000)
                } else {
                    chrrom.bankedRead(at: address, bankIndex: Int(chrbank0) & 0xFFFE, bankSize: 0x1000)
                }
            case 0x1000...0x1FFF:
                if Bool(control & 0b0001_0000) {
                    chrrom.bankedRead(at: address, bankIndex: Int(chrbank1), bankSize: 0x1000)
                } else {
                    chrrom.bankedRead(at: address, bankIndex: Int(chrbank0 | 1), bankSize: 0x1000)
                }
            case 0x2000...0x3FFF:
                vram.read(at: nametableLayout.map(address))
            default:
                nil
        }
    }
    
    func ppuWrite(_ data: u8, at address: u16) {
        switch address {
            case 0x0000...0x0FFF:
                if Bool(control & 0b0001_0000) {
                    chrrom.bankedWrite(data, at: address, bankIndex: Int(chrbank0), bankSize: 0x1000)
                } else {
                    chrrom.bankedWrite(data, at: address, bankIndex: Int(chrbank0) & 0xFFFE, bankSize: 0x1000)
                }
            case 0x1000...0x1FFF:
                if Bool(control & 0b0001_0000) {
                    chrrom.bankedWrite(data, at: address, bankIndex: Int(chrbank1), bankSize: 0x1000)
                } else {
                    chrrom.bankedWrite(data, at: address, bankIndex: Int(chrbank0 | 1), bankSize: 0x1000)
                }
            case 0x2000...0x3FFF:
                vram.write(data, at: nametableLayout.map(address))
            default:
                break
        }
    }
}
