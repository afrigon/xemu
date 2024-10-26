import Foundation
import XemuFoundation

/// https://www.nesdev.org/wiki/MMC1
class MapperMMC1: Mapper {
    var type: MapperType = .mmc1
    
    let pgrrom: Memory
    let chrrom: Memory
    let sram: Memory
    
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

    init(pgrrom: Memory, chrrom: Memory, sram: Memory) {
        self.pgrrom = pgrrom
        self.chrrom = chrrom
        self.sram = sram
    }
    
    required init(from iNes: iNesFile, saveData: Data) {
        pgrrom = .init(iNes.pgrrom)
        chrrom = .init(iNes.chrrom)
        sram = .init(saveData)
    }
    
    func cpuRead(at address: u16) -> u8? {
        writeEnabled = true
        
        switch address {
            case 0x6000..<0x8000:
                return sram.read(at: address - 0x6000)
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
                sram.write(data, at: address - 0x6000)
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
                        
                        switch u8(address >> 13 & 0b11) {
                            case 0b00:
                                control = value
                            case 0b01:
                                chrbank0 = value
                            case 0b10:
                                chrbank1 = value
                            case 0b11:
                                pgrbank = value
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
        nil
    }
    
    func ppuWrite(_ data: u8, at address: u16) {
        
    }
}
