import Foundation
import XemuFoundation

class PPU: Codable {
    weak var bus: Bus!
    
    var dot: Int = 0
    var scanline: Int = 0
    
    /// PPUCTRL - Miscellaneous settings ($2000 write)
    ///
    /// PPUCTRL contains a mix of settings related to rendering, scroll position,
    /// vblank NMI, and dual-PPU configurations.
    ///
    /// - note: After power/reset, writes to this register are ignored until the first pre-render scanline.
    ///
    /// ```
    /// 7  bit  0
    /// ---- ----
    /// VPHB SINN
    /// |||| ||||
    /// |||| ||++- Base nametable address
    /// |||| ||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
    /// |||| |+--- VRAM address increment per CPU read/write of PPUDATA
    /// |||| |     (0: add 1, going across; 1: add 32, going down)
    /// |||| +---- Sprite pattern table address for 8x8 sprites
    /// ||||       (0: $0000; 1: $1000; ignored in 8x16 mode)
    /// |||+------ Background pattern table address (0: $0000; 1: $1000)
    /// ||+------- Sprite size (0: 8x8 pixels; 1: 8x16 pixels – see PPU OAM#Byte 1)
    /// |+-------- PPU master/slave select
    /// |          (0: read backdrop from EXT pins; 1: output color on EXT pins)
    /// +--------- Vblank NMI enable (0: off, 1: on)
    /// ```
    var control: u8 = 0
    
    /// PPUMASK - Rendering settings ($2001 write)
    /// PPUMASK controls the rendering of sprites and backgrounds, as well as color effects.
    ///
    /// - note: After power/reset, writes to this register are ignored until the first pre-render scanline.
    ///
    /// Most commonly, PPUMASK is set to $00 outside of gameplay to allow
    /// transferring a large amount of data to VRAM, and $1E during gameplay to
    /// enable all rendering with no color effects.
    ///
    /// ```
    /// 7  bit  0
    /// ---- ----
    /// BGRs bMmG
    /// |||| ||||
    /// |||| |||+- Greyscale (0: normal color, 1: greyscale)
    /// |||| ||+-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
    /// |||| |+--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
    /// |||| +---- 1: Enable background rendering
    /// |||+------ 1: Enable sprite rendering
    /// ||+------- Emphasize red (green on PAL/Dendy)
    /// |+-------- Emphasize green (red on PAL/Dendy)
    /// +--------- Emphasize blue
    /// ```
    var mask: u8 = 0
    
    /// PPUSTATUS - Rendering events ($2002 read)
    ///
    /// ```
    /// 7  bit  0
    /// ---- ----
    /// VSOx xxxx
    /// |||| ||||
    /// |||+-++++- (PPU open bus or 2C05 PPU identifier)
    /// ||+------- Sprite overflow flag
    /// |+-------- Sprite 0 hit flag
    /// +--------- Vblank flag, cleared on read. Unreliable.
    /// ```
    var status: u8 = 0
    
    var oamAddress: u8 = 0
    
    /// Internal Register v
    ///
    /// - During rendering, used for the scroll position.
    /// - Outside of rendering, used as the current VRAM address.
    var v: u16 = 0
    
    /// Internal Register t
    ///
    /// - During rendering, specifies the starting coarse-x scroll for the next
    /// scanline and the starting y scroll for the screen.
    /// - Outside of rendering, holds the scroll or VRAM address before transferring it to v.
    ///
    ///
    /// ```
    /// 15      bit       0
    ///  ------------------
    ///  yyy_nn_YYYYY_XXXXX
    ///  ||| || ||||| |||||
    ///  ||| || ||||| +++++- Coarse X (nametable x coordinate)
    ///  ||| || +++++------- Coarse Y (nametable y coordinate)
    ///  ||| ++------------- Nametable Index
    ///  +++---------------- fine Y (Pattern Y offset)
    /// ```
    var t: u16 = 0b000_00_00000_00000
    
    /// Internal Register x
    ///
    /// The fine-x position of the current scroll, used during rendering alongside v.
    var x: u16 = 0

    /// Internal Register w
    ///
    /// Toggles on each write to either PPUSCROLL or PPUADDR,
    /// indicating whether this is the first or second write.
    ///
    /// - note: Clears on reads of PPUSTATUS.
    var w: Bool = false
    
    var oam: [u8] = .init(repeating: 0, count: 256)
    
    // Internal latches, holds the data before being fed to the appropriate shift registers
    var patternIndex: u16 = 0
    var attribute: u8 = 0
    var patternLO: u16 = 0
    var patternHI: u16 = 0
    
    // Shift Registers
    var shiftPatternLO: u16 = 0
    var shiftPatternHI: u16 = 0
    
    var latch: u8 = 0
    var readBuffer: u8 = 0
    private var isOddFrame: Bool = false
    
    private var needsRender = true // TODO: having only 1 framebuffer might cause screen tearing if the renderer is not synced with the vblank
    private var frameBuffer = Data(repeating: 1, count: 256 * 240)
    
    var frame: Data? {
        guard needsRender else {
            return nil
        }
        
        needsRender = false
        
        return frameBuffer
    }

    init(bus: Bus) {
        self.bus = bus
    }
    
    var spritesEnabled: Bool {
        Bool(self.mask & 0b0001_0000)
    }
    
    var backgroundEnabled: Bool {
        Bool(self.mask & 0b0000_1000)
    }
    
    var renderingEnabled: Bool {
        Bool(self.mask & 0b0001_1000)
    }
    
    var y: u16 {
        get {
            v >> 12
        }
    }

    func incrementY() {
        if v & 0b111_00_00000_00000 == 0b111_00_00000_00000 {
            v = v & 0b000_11_11111_11111
            incrementCoarseY()
        } else {
            v += 0b001_00_00000_00000
        }
    }
    
    func incrementCoarseX() {
        // if coarse X is overflowing
        if v & 0b000_00_00000_11111 == 0b000_00_00000_11111 {
            v = (v & 0b111_11_11111_00000) // coarse Y wraps around to 0
              ^ 0b000_01_00000_00000       // next horizontal nametable
        } else {
            v += 0b000_00_00000_00001
        }
    }
    
    func incrementCoarseY() {
        // if coarse Y is overflowing
        if v & 0b000_00_11111_00000 == 0b000_00_11111_00000 {
            v = (v & 0b111_11_00000_11111) // coarse Y wraps around to 0
              ^ 0b000_10_00000_00000       // next vertical nametable
        } else {
            v += 0b000_00_00001_00000
        }
    }
    
    private func shiftBackgroundRegisters() {
        shiftPatternLO <<= 1
        shiftPatternHI <<= 1
    }

    private func fetchBackground(subcycle: Int) {
        switch subcycle {
            case 0:
                incrementCoarseX()
                
                shiftPatternLO = shiftPatternLO | patternLO
                shiftPatternHI = shiftPatternHI | patternHI
            case 1:  // nametable
                let address = 0x2000 | (v & 0x0FFF)
                patternIndex = u16(bus.ppuRead(at: address))
            case 3:  // attribute https://wiki.nesdev.com/w/index.php/PPU_scrolling#Tile_and_attribute_fetching
                let address = 0x23C0 | (v & 0x0C00) | ((v >> 4) & 0x38) | ((v >> 2) & 0x07)
                attribute = bus.ppuRead(at: address)
            case 5:  // pattern lsb
                var address = patternIndex * 16 + y
                
                if Bool(control & 0x10) {
                    address += 0x1000
                }
                
                patternLO = u16(bus.ppuRead(at: address))
            case 7:  // pattern msb
                var address = patternIndex * 16 + y + 8
                
                if Bool(control & 0x10) {
                    address += 0x1000
                }
                
                patternHI = u16(bus.ppuRead(at: address))
            default:
                break
        }
    }
    
    private func drawPixel() {
        let patternMask: u16 = 0b1000_0000_0000_0000 >> x
        let patternShift = 15 - x
        let paletteIndex = (shiftPatternHI & patternMask) >> (patternShift - 1) |
                           (shiftPatternLO & patternMask) >> patternShift
        
        frameBuffer[256 * scanline + (dot - 1)] = u8(paletteIndex * 5)
    }
    
    private func render() {
        if renderingEnabled {
            switch dot {
                case 0:
                    // TODO: do fake bg access
                    break
                case 1...256:
                    drawPixel()
                    shiftBackgroundRegisters()
                    fetchBackground(subcycle: (dot - 1) % 8)
                    
                    if dot == 256 {
                        incrementY()
                    }
                case 257...320:
                    if dot == 257 {
                        v &= 0b111_10_11111_00000
                        v |= t & 0b01_00000_11111
                    }
                    
                    // TODO: fetch sprites
                case 321...336:
                    shiftBackgroundRegisters()
                    fetchBackground(subcycle: (dot - 1) % 8)
                    
                case 338:
                    // TODO: fake nt fetch
                    break
                case 340:
                    // TODO: fake nt fetch
                    break

                default:
                    break
            }
        } else {
            switch dot {
                case 1...256:
                    let paletteIndex: u8
                    
                    if v >= 0x3F00 && v <= 0x3FFF {
                        paletteIndex = bus.ppuRead(at: v)
                    } else {
                        paletteIndex = bus.ppuRead(at: 0x3f00)
                    }
                    
                    frameBuffer[256 * scanline + (dot - 1)] = paletteIndex
                default:
                    break
            }
        }
    }
    
    private func vblank() {
        if dot == 1 {
            status |= 0b1000_0000
            
            if renderingEnabled {
                needsRender = true
            }
        }
    }
    
    private func prerender() {
        guard renderingEnabled else {
            if dot == 1 {
                status &= 0b0111_1111
            }
            
            return
        }
        
        switch dot {
            case 2...256:
                fetchBackground(subcycle: (dot - 1) % 8)
            case 257:
                v &= 0b111_10_11111_00000
                v |= t & 0b000_01_00000_11111
            case 258...279:
                // TODO: fetch sprites
                break
            case 280...304:
                v &= 0b000_01_00000_11111
                v |= t & 0b111_10_11111_00000
                
                // TODO: fetch sprites
            case 305...320:
                // TODO: fetch sprites
                break
            case 321...336:
                shiftBackgroundRegisters()
                fetchBackground(subcycle: (dot - 1) % 8)
            case 338:
                // TODO: fake nt fetch
                break
            case 340:
                // TODO: fake nt fetch
                
                // The first dot after an odd frame is skipped,
                if isOddFrame {
                    
                    // these counter will be incremented before the cycle ends
                    scanline = 0
                    dot = 0
                    isOddFrame = false
                } else {
                    isOddFrame = true
                }
            default:
                break
        }
    }

    func clock() {
        switch scanline {
            case 0..<240:
                render()
            case 240:
                if dot == 1 && renderingEnabled {
                    bus.ppuRead(at: v)
                }
            case 241:
                vblank()
            case 261:
                prerender()
            default:
                break
        }
        
        dot += 1
        if dot > 340 {
            dot = 0
            scanline += 1
            
            if scanline > 261 {
                scanline = 0
                isOddFrame.toggle()
            }
        }
    }
    
    // TODO: update this with all the keys when done implementing apu
    enum CodingKeys: CodingKey {
        case dot
        case scanline
        case control
        case mask
        case status
        case oamAddress
        case v
        case t
        case x
        case w
        case oam
        case patternIndex
        case attribute
        case patternLO
        case patternHI
        case shiftPatternLO
        case shiftPatternHI
        case latch
        case readBuffer
        case isOddFrame
        case needsRender
        case frameBuffer
    }
}
