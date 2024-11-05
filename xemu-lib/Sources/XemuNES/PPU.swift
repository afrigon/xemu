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
    var control: u8 = 0 {
        didSet {
            bus.setNMI(Bool(control & status & 0b1000_0000))
        }
    }

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
    var mask: u8 = 0 {
        didSet {
            spritesEnabled = Bool(self.mask & 0b0001_0000)
            backgroundEnabled = Bool(self.mask & 0b0000_1000)
            renderingEnabled = spritesEnabled || backgroundEnabled
        }
    }
    
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
    var status: u8 = 0 {
        didSet {
            bus.setNMI(Bool(control & status & 0b1000_0000))
        }
    }
    
    var oamAddress: u8 = 0
    
    /// Internal Register v
    ///
    /// - During rendering, used for the scroll position.
    /// - Outside of rendering, used as the current VRAM address.
    var v: u16 = 0 {
        didSet {
            y = v >> 12
        }
    }
    
    var y: u16 = 0

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
    var oamSecondary: [Sprite?] = .init(repeating: nil, count: 8)
    var spriteZeroFound: Bool = false

    // Internal latches, holds the data before being fed to the appropriate shift registers
    var patternIndex: u16 = 0
    var attribute: u8 = 0
    var patternLO: u16 = 0
    var patternHI: u16 = 0
    
    // Shift Registers
    var shiftPatternLO: u16 = 0
    var shiftPatternHI: u16 = 0
    var shiftAttribute: u16 = 0

    var latch: u8 = 0
    var readBuffer: u8 = 0
    var suppressVblank: Bool = false
    private var isOddFrame: Bool = false

    private var needsRender = true
    private var frameBuffer: [u8] = .init(repeating: 0, count: 256 * 240)
    
    var frame: [u8]? {
        guard needsRender else {
            return nil
        }
        
        needsRender = false
        
        return frameBuffer
    }

    init(bus: Bus) {
        self.bus = bus
    }
    
    var spritesEnabled: Bool = false
    var backgroundEnabled: Bool = false
    var renderingEnabled: Bool = false

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
    
    private func shiftSprites() {
        for i in 0..<8 {
            guard var sprite = oamSecondary[i] else {
                continue
            }
            
            guard sprite.x == 0 else {
                sprite.x -= 1
                oamSecondary[i] = sprite
                continue
            }
            
            if Bool(sprite.attribute & 0b0100_0000) {
                sprite.patternLO = (sprite.patternLO ?? 0) >> 1
                sprite.patternHI = (sprite.patternHI ?? 0) >> 1
            } else {
                sprite.patternLO = (sprite.patternLO ?? 0) << 1
                sprite.patternHI = (sprite.patternHI ?? 0) << 1
            }
            
            oamSecondary[i] = sprite
        }
    }

    private func fetchBackground(subcycle: Int) {
        switch subcycle {
            case 0:
                if dot != 321 {
                    shiftPatternLO = shiftPatternLO | patternLO
                    shiftPatternHI = shiftPatternHI | patternHI
                    
                    // coarse_x bit 1 and coarse_y bit 1 select 2 bits from attribute byte
                    let attributeShift = (v & 0b000_00_00010_00000) >> 4 |
                                         (v & 0b000_00_00000_00010)
                    let attributeValue = attribute >> attributeShift & 0b11
                    shiftAttribute = shiftAttribute << 2 | u16(attributeValue)
                    
                    incrementCoarseX()
                }
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
    
    private func resetSprites() {
        for i in 0..<8 {
            oamSecondary[i] = nil
        }
    }
    
    // TODO: should this be done during background fetches
    private func findVisibleSprites() {
        let spriteSize: u8 = Bool(control & 0b0010_0000) ? 16 : 8
        
        spriteZeroFound = false
        
        resetSprites()
        
        var count = 0
        
        for i in 0..<64 {
            let index = i * 4
            
            let y = oam[index]
            
            guard scanline >= y && scanline < y + spriteSize else {
                continue
            }
            
            guard count < 8 else {
                return status |= 0b0010_0000 // sprite overflow
            }
            
            oamSecondary[count] = Sprite(
                x: oam[index + 3],
                y: y,
                patternIndex: oam[index + 1],
                attribute: oam[index + 2]
            )
            
            if i == 0 {
                spriteZeroFound = true
            }
                
            count += 1
        }
    }
    
    private func fetchSprites(subcycle: Int) {
        switch subcycle {
            case 1, 3:
                bus.ppuRead(at: 0x2000 | (v & 0x0FFF))
            case 5, 7:
                let index = (dot - 257) / 8
                
                guard var sprite = oamSecondary[index] else {
                    return
                }
                
                let spriteSize: u8 = Bool(control & 0b0010_0000) ? 16 : 8
                
                var patternIndex = u16(sprite.patternIndex)
                var patternAddress: u16 = 0x0000

                if spriteSize == 16 {
                    if Bool(patternIndex & 1) {
                        patternAddress = 0x1000
                    }
                    
                    patternIndex &= 0b1111_1110
                } else {
                    if Bool(control & 0b0000_1000) {
                        patternAddress = 0x1000
                    }
                }
                
                var offsetY = scanline - Int(sprite.y)
                if Bool(sprite.attribute & 0b1000_0000) { // vertical flip
                    offsetY = Int(spriteSize - 1) - offsetY
                }
                
                if offsetY >= 8 {
                    offsetY -= 8
                    patternIndex += 1
                }
                offsetY %= 8
                
                patternAddress |= (patternIndex * 16 + u16(offsetY)) & 0x0FFF
                
                switch subcycle {
                    case 5:
                        sprite.patternLO = bus.ppuRead(at: patternAddress)
                    case 7:
                        sprite.patternHI = bus.ppuRead(at: patternAddress + 8)
                    default:
                        break
                }
                
                oamSecondary[index] = sprite
            default:
                break
        }
    }
    
    private func drawPixel() {
        let background: u8
        let backgroundPatternValue: u16
        
        if backgroundEnabled || (dot <= 8 && Bool(mask & 0b0000_0010)) {
            let patternMask: u16 = 0b1000_0000_0000_0000 >> x
            let patternShift = 15 - x
            backgroundPatternValue = (shiftPatternHI & patternMask) >> (patternShift - 1) |
            (shiftPatternLO & patternMask) >> patternShift
            
            let attributeValue = (shiftAttribute >> 2) & 0b11
            
            background = bus.ppuRead(at: 0x3F00 + attributeValue << 2 + backgroundPatternValue)
        } else {
            background = bus.ppuRead(at: 0x3F00)
            backgroundPatternValue = 0
        }
        
        frameBuffer[256 * scanline + (dot - 1)] = background
        
        if spritesEnabled || (dot <= 8 && Bool(mask & 0b0000_0100)) {
            for (i, sprite) in oamSecondary.enumerated() {
                guard let sprite, sprite.x == 0 else {
                    continue
                }
                
                let patternValue = if Bool(sprite.attribute & 0b0100_0000) { // horizontal flip
                    (((sprite.patternHI ?? 0) & 0b0000_0001) << 1) |
                    (((sprite.patternLO ?? 0) & 0b0000_0001)     )
                } else {
                    (((sprite.patternHI ?? 0) & 0b1000_0000) >> 6) |
                    (((sprite.patternLO ?? 0) & 0b1000_0000) >> 7)
                }
                
                guard Bool(patternValue) else {
                    continue
                }
                
                if spriteZeroFound && i == 0 && Bool(backgroundPatternValue) {
                    status |= 0b0100_0000
                }
                
                if !Bool(backgroundPatternValue) || !Bool(sprite.attribute & 0b0010_0000) { // priority
                    let attributeValue = u16(sprite.attribute & 0b11)
                    frameBuffer[256 * scanline + (dot - 1)] = bus.ppuRead(at: 0x3F10 + attributeValue << 2 + u16(patternValue))
                }
                
                break
            }
        }
    }
    
    private func render() {
        if renderingEnabled {
            switch dot {
                case 0:
                    break
                case 1...256:
                    shiftBackgroundRegisters()
                    shiftSprites()
                    
                    fetchBackground(subcycle: (dot - 1) % 8)
                    drawPixel()

                    if dot == 256 {
                        incrementY()
                    }
                case 257:
                    v &= 0b111_10_11111_00000
                    v |= t & 0b01_00000_11111
                    
                    findVisibleSprites()
                    fetchSprites(subcycle: (dot - 1) % 8)
                case 258...320:
                    fetchSprites(subcycle: (dot - 1) % 8)
                case 321...336:
                    shiftBackgroundRegisters()
                    fetchBackground(subcycle: (dot - 1) % 8)
                case 338, 340:
                    self.patternIndex = u16(bus.ppuRead(at: 0x2000 | (v & 0x0FFF)))
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
            if !suppressVblank {
                status |= 0b1000_0000
            }
            
            if renderingEnabled {
                needsRender = true
            }
            
            suppressVblank = false
        }
    }
    
    private func prerender() {
        guard renderingEnabled else {
            if dot == 1 {
                status &= 0b0001_1111
            }
            
            return
        }
        
        switch dot {
            case 1:
                status &= 0b0001_1111
            case 2...256:
                fetchBackground(subcycle: (dot - 1) % 8)
            case 257:
                v &= 0b111_10_11111_00000
                v |= t & 0b000_01_00000_11111
                
                resetSprites()
                fetchSprites(subcycle: (dot - 1) % 8)
            case 258...279:
                fetchSprites(subcycle: (dot - 1) % 8)
            case 280...304:
                v &= 0b000_01_00000_11111
                v |= t & 0b111_10_11111_00000
                
                fetchSprites(subcycle: (dot - 1) % 8)
            case 305...320:
                fetchSprites(subcycle: (dot - 1) % 8)
            case 321...336:
                shiftBackgroundRegisters()
                fetchBackground(subcycle: (dot - 1) % 8)
            case 338:
                self.patternIndex = u16(bus.ppuRead(at: 0x2000 | (v & 0x0FFF)))
            case 340:
                self.patternIndex = u16(bus.ppuRead(at: 0x2000 | (v & 0x0FFF)))
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
                
                if isOddFrame && renderingEnabled {
                    dot = 1
                }
                
                isOddFrame.toggle()
            }
        }
    }
    
    // TODO: update this with all the keys when done implementing ppu
    enum CodingKeys: CodingKey {
        case dot
        case scanline
        case control
        case mask
        case status
        case oamAddress
        case v
        case t
        case y
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
        case backgroundEnabled
        case spritesEnabled
        case renderingEnabled
    }
    
    struct Sprite: Codable {
        var x: u8
        var y: u8
        var patternIndex: u8
        var attribute: u8
        
        var patternLO: u8? = nil
        var patternHI: u8? = nil
    }
}
