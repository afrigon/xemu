import Foundation
import XemuFoundation
import XemuCore

final class PPU: Codable {
    private(set) var dot: Int = 340
    private(set) var scanline: Int = -1

    private var readBuffer: u8 = 0
    private var latch: u8 = 0
    var busAddress: u16 = 0

    private var control: PPUControlRegister = .init()
    private var mask: PPUMaskRegister = .init()
    private var status: PPUStatusRegister = .init()
    private var suppressVBlank: Bool = false
    
    private var w: Bool = false
    private var x: u8 = 0
    private var t: u16 = 0
    
    private var v: u16 = 0
    private var vNext: u16 = 0
    private var vDelay: u8 = 0
    private var vDirty: Bool = false
    private var vSuppress: u8 = 0
    
    private var tile: Tile = .init()
    private var lo: u16 = 0
    private var hi: u16 = 0
    
    private var tilePalette: u8 = 0
    private var oldTilePalette: u8 = 0

    private var dirty: Bool = false
    private var renderingEnabled: Bool = true
    private var oldRenderingEnabled: Bool = true

    var frameCount: Int = 0
    private var frameBuffer: [u8] = .init(repeating: 0, count: 256 * 240)
    
    private var clock: i64 = 0
    private var divider: i64 = 4
    
    private var firstBackgroundDot: u16 = 0
    private var firstSpriteDot: u16 = 0
    
    private var paletteRAM: [u8] = [
        0x09, 0x01, 0x00, 0x01, 0x00, 0x02, 0x02, 0x0D, 0x08, 0x10, 0x08, 0x24, 0x00, 0x00, 0x04, 0x2C,
        0x09, 0x01, 0x34, 0x03, 0x00, 0x04, 0x00, 0x14, 0x08, 0x3A, 0x00, 0x02, 0x00, 0x20, 0x2C, 0x08
    ]

    var frame: [u8] {
        frameBuffer
    }
    
    weak var bus: Bus!

    init(bus: Bus) {
        self.bus = bus
    }
    
    func reset(type: ResetType) {
        clock = 0
        
        suppressVBlank = false
        dirty = false
        oldRenderingEnabled = false
        renderingEnabled = false
        readBuffer = 0
        latch = 0
        busAddress = 0
        
        x = 0
        w = false
        
        lo = 0
        hi = 0
        tile = .init()
        tilePalette = 0
        oldTilePalette = 0
        
        control = .init()
        mask = .init()
        
        if type == .powerCycle {
            v = 0
            status = .init()
        }
        
        t = 0
        vNext = 0
        vDelay = 0
        vSuppress = 0
        vDirty = false
        
        scanline = -1
        dot = 340
        
        frameCount = 1
        
        cacheFirstDrawDots()
    }
    
    private func cacheFirstDrawDots() {
        firstBackgroundDot = mask.backgroundEnabled ? (mask.backgroundMask ? 0 : 8) : 300
        firstSpriteDot = mask.spritesEnabled ? (mask.spritesMask ? 0 : 8) : 300
    }
    
    private func setControl(_ data: u8) {
        let nametable = data & 0b11
        t = (t & ~0x0C00) | (u16(nametable) << 10)
        
        // TODO: set missing stuff
        control.verticalIncrement = data & 0x04 == 0x04 ? 32 : 1
        control.spritePatternAddress = data & 0x08 == 0x08 ? 0x1000 : 0x0000
        control.backgroundPatternAddress = data & 0x10 == 0x10 ? 0x1000 : 0x0000
        control.nmiOnVBlank = data & 0x80 == 0x80
        
        // setting nmiOnVBlank during a vblank without reading 0x2002 can cause multiple nmi to be generated
        if !control.nmiOnVBlank {
            bus.setNMI(false)
        } else if control.nmiOnVBlank && status.verticalBlank {
            bus.setNMI(true)
        }
    }
    
    private func setMask(_ data: u8) {
        mask.grayscale = data & 0x01 == 0x01
        mask.backgroundMask = data & 0x02 == 0x02
        mask.spritesMask = data & 0x04 == 0x04
        mask.backgroundEnabled = data & 0x08 == 0x08
        mask.spritesEnabled = data & 0x10 == 0x10
        mask.emphasizeRed = data & 0x20 == 0x20
        mask.emphasizeGreen = data & 0x40 == 0x40
        mask.emphasizeBlue = data & 0x80 == 0x80
        
        if renderingEnabled != (mask.backgroundEnabled || mask.spritesEnabled) {
            dirty = true
        }
        
        cacheFirstDrawDots()
    }
    
    private func shift() {
        lo <<= 1
        hi <<= 1
    }
    
    // Taken from http://wiki.nesdev.com/w/index.php/The_skinny_on_NES_scrolling#Tile_and_attribute_fetching
    private func nametableAddress() -> u16 {
        0x2000 | (v & 0x0fff)
    }
    
    // Taken from http://wiki.nesdev.com/w/index.php/The_skinny_on_NES_scrolling#Tile_and_attribute_fetching
    private func attributeAddress() -> u16 {
        return 0x23C0 | (v & 0x0C00) | ((v >> 4) & 0x38) | ((v >> 2) & 0x07)
    }
    
    // Taken from http://wiki.nesdev.com/w/index.php/The_skinny_on_NES_scrolling#Wrapping_around
    private func incVerticalScroll() {
        var address = v

        if (address & 0x7000) != 0x7000 {
            // if fine Y < 7
            address &+= 0x1000  // increment fine Y
        } else {
            // fine Y = 0
            address &= ~0x7000
            var y = (address & 0x03E0) >> 5  // let y = coarse Y
            
            if y == 29 {
                y = 0  // coarse Y = 0
                address ^= 0x0800  // switch vertical nametable
            } else if y == 31 {
                y = 0  // coarse Y = 0, nametable not switched
            } else {
                y &+= 1  // increment coarse Y
            }
            
            address = (address & ~0x03E0) | (y << 5)  // put coarse Y back into v
        }
        
        v = address
    }

    // Taken from http://wiki.nesdev.com/w/index.php/The_skinny_on_NES_scrolling#Wrapping_around
    private func incHorizontalScroll() {
        // Increase coarse X scrolling value.
        var address = v
        
        // When the value is 31, wrap around to 0 and switch nametable
        if (address & 0x001F) == 31 {
            address = (address & ~0x001F) ^ 0x0400
        } else {
            address &+= 1
        }
        
        v = address
    }

    func debugRead(at address: u16) -> u8 {
        switch address & 7 {
            case 2:
                return status.value
            case 4:
                return latch
            case 7:
                return latch
            default:
                return latch
        }
    }

    func read(at address: u16) -> u8 {
        switch address & 7 {
            case 2:
                w = false
                
                let value = status.value
                
                status.verticalBlank = false
                bus.setNMI(false)
                
                if scanline == 241 && dot == 0 {
                    suppressVBlank = true
                }
                
                // TODO: update latch with mask
                latch = value
                
                return value
            case 4:
                return latch
            case 7:
                if vSuppress > 0 {
                    return latch
                }
                
                var value = readBuffer
                readBuffer = bus.ppuRead(at: busAddress & 0x3fff)
                
                if busAddress & 0x3fff >= 0x3f00 {
                    value = (readPalette(at: busAddress) & 0x3f) | (latch & 0xc0)
                }
                
                latch = value
                dirty = true
                vDirty = true
                vSuppress = 6
                return latch
            default:
                return latch
        }
    }

    func write(_ data: u8, at address: u16) {
        latch = data
        
        switch address & 7 {
            case 0:  // PPUCTRL
                setControl(data)
            case 1:  // PPUMASK
                setMask(data)
            case 3:  // OAMADDR
                break
            case 4:  // OAMDATA
                break
            case 5:  // PPUSCROLL
                if w {
                    t = (t & ~0x73e0) | (u16(data & 0xf8) << 2) | (u16(data & 0x07) << 12)
                } else {
                    x = data & 0x07
                    
                    // TODO: process glitch ?
                    t = (t & ~0x001f) | u16(data >> 3)
                }
                
                w.toggle()
            case 6:  // PPUADDR
                if w {
                    t = (t & ~0x00ff) | u16(data)
                    vNext = t
                    vDelay = 3
                    dirty = true
                } else {
                    // TODO: process glitch ?
                    t = (t & ~0xff00) | (u16(data & 0x3f) << 8)
                }
                
                w.toggle()
            case 7:  // PPUDATA
                if busAddress & 0x3fff >= 0x3f00 {
                    writePalette(data, at: busAddress)
                } else {
                    if scanline >= 240 || !renderingEnabled {
                        bus.ppuWrite(data, at: busAddress & 0x3fff)
                    } else {
                        bus.ppuWrite(u8(busAddress & 0xff), at: busAddress & 0x3fff)
                    }
                }
                
                dirty = true
                vDirty = true
            default:
                break
        }
    }
    
    private func readPalette(at address: u16) -> u8 {
        var address = address & 0x1f
        
        if address == 0x10 || address == 0x14 || address == 0x18 || address == 0x1c {
            address &= 0x10
        }
        
        return paletteRAM[Int(address)]
    }
    
    private func writePalette(_ data: u8, at address: u16) {
        let address = address & 0x1f
        let data = data & 0x3f
        
        if address == 0x00 || address == 0x10 {
            paletteRAM[0x00] = data
            paletteRAM[0x10] = data
        } else if address == 0x04 || address == 0x14 {
            paletteRAM[0x04] = data
            paletteRAM[0x14] = data
        } else if address == 0x08 || address == 0x18 {
            paletteRAM[0x08] = data
            paletteRAM[0x18] = data
        } else if address == 0x0c || address == 0x1c {
            paletteRAM[0x0c] = data
            paletteRAM[0x1c] = data
        } else {
            paletteRAM[Int(address)] = data
        }
    }
    
    private func drawPixel() {
        if renderingEnabled || (v & 0x3f00) != 0x3f00 {
            let color = pixelColor()
            frameBuffer[(scanline << 8) + dot - 1] = paletteRAM[Int(Bool(color & 0x03) ? color : 0)]
        } else {
            frameBuffer[(scanline << 8) + dot - 1] = paletteRAM[Int(v & 0x1f)]
        }
    }
    
    private func pixelColor() -> u8 {
        let offset = x
        var background: u8 = 0
        var sprite: u8 = 0

        if dot > firstBackgroundDot {
            sprite = u8((((lo << offset) & 0x8000) >> 15) | (((hi << offset) & 0x8000) >> 14))
            background = sprite
        }
        
        return ((u8(Int(offset) &+ ((dot - 1) & 0x07)) < 8) ? oldTilePalette : tilePalette) + background
    }
    
    private func fetchTile() {
        guard renderingEnabled else {
            return
        }
        
        switch dot & 0x07 {
            case 1:
                oldTilePalette = tilePalette
                tilePalette = tile.paletteOffset
                
                lo |= u16(tile.lo)
                hi |= u16(tile.hi)
                
                let tileIndex = bus.ppuRead(at: nametableAddress())
                tile.address = (u16(tileIndex) << 4) | (v >> 12) | control.backgroundPatternAddress
            case 3:
                let shift = ((v >> 4) & 0x04) | (v & 0x02)
                tile.paletteOffset = ((bus.ppuRead(at: attributeAddress()) >> shift) & 0x03) << 2
            case 5:
                tile.lo = bus.ppuRead(at: tile.address)
            case 7:
                tile.hi = bus.ppuRead(at: tile.address &+ 8)
            default:
                break
        }
    }
    
    private func firstDot() {
        dot = 0
        scanline += 1
        
        if scanline > 260 {
            scanline = -1
            
            cacheFirstDrawDots()
        }
        
        if scanline < 240 {
            if scanline == -1 {
                
            } else if oldRenderingEnabled {
                if scanline > 0 || u8(truncatingIfNeeded: frameCount) & 1 == 0 {
                    busAddress = (tile.address << 4) | (v >> 12) | control.backgroundPatternAddress
                }
            }
        } else if scanline == 240 {
            busAddress = v & 0x3fff
            frameCount += 1
        }
    }
    
    private func processScanline() {
        if dot <= 256 {
            fetchTile()
            
            if oldRenderingEnabled && (dot & 0x07) == 0 {
                incHorizontalScroll()
                
                if dot == 256 {
                    incVerticalScroll()
                }
            }
            
            if scanline >= 0 {
                drawPixel()
                shift()
            } else {
                if dot == 1 {
                    status.verticalBlank = false
                    bus.setNMI(false)
                }
            }
        } else if dot >= 257 && dot <= 320 {
            if dot == 257 {
                // TODO: add sprite stuff
                
                if oldRenderingEnabled {
                    v = (v & ~0x041F) | (t & 0x041F)
                }
            }
                
            if renderingEnabled {
                // TODO: sprite stuff
                
                switch (dot - 257) % 8 {
                    case 0:
                        bus.ppuRead(at: nametableAddress())
                    case 2:
                        bus.ppuRead(at: attributeAddress())
                    case 4:
                        // TODO: some sprite stuff
                        break
                    default:
                        break
                }
                
                if scanline == -1 && dot >= 280 && dot <= 304 {
                    v = (v & ~0x7BE0) | (t & 0x7BE0)
                }
                
                if dot == 320 {
                    // TODO: some sprite stuff
                }
            }
        } else if dot >= 321 && dot <= 336 {
           fetchTile()
            
            if dot == 321 {
                // TODO: some oam stuff
            } else if oldRenderingEnabled && (dot == 328 || dot == 336) {
                lo <<= 8
                hi <<= 8
                incHorizontalScroll()
            }
        } else if dot == 337 || dot == 339 {
            if renderingEnabled {
                tile.address = u16(bus.ppuRead(at: nametableAddress()))
                
                if scanline == -1 && dot == 339 && (frameCount & 1) == 1 {
                    dot = 340
                }
            }
        }
    }
    
    func step() {
        if dot < 340 {
            dot += 1
            
            if scanline < 240 {
                processScanline()
            } else if dot == 1 && scanline == 241 {
                if !suppressVBlank {
                    status.verticalBlank = true
                    bus.setNMI(true)
                }
                
                suppressVBlank = false
            }
        } else {
            firstDot()
        }
        
        if dirty {
            update()
        }
    }
    
    func step(until cycle: Int) {
        step()
        clock += divider
        
        while clock + divider <= cycle {
            step()
            clock += divider
        }
    }
    
    private func update() {
        dirty = false
        
        // emulates the 1 cycle delay when enabling/disabling rendering
        if renderingEnabled != oldRenderingEnabled {
            oldRenderingEnabled = renderingEnabled
            
            if scanline < 240 {
                if oldRenderingEnabled {
                    // TODO: oam corruption
                } else {
                    // TODO: oam corruption
                    
                    busAddress = v & 0x3fff
                    
                    if dot >= 65 && dot <= 256 {
                        // TODO: sprite stuff
                    }
                }
            }
        }
        
        let newRenderingEnabled = mask.backgroundEnabled || mask.spritesEnabled
        if renderingEnabled != newRenderingEnabled {
            renderingEnabled = newRenderingEnabled
            dirty = true
        }
        
        if vDelay > 0 {
            vDelay -= 1
            
            if vDelay == 0 {
                v = vNext
                t = vNext
                
                if scanline >= 240 || !renderingEnabled {
                    busAddress = v & 0x3fff
                }
            } else {
                dirty = true
            }
        }
        
        if vSuppress > 0 {
            vSuppress -= 1
            
            if vSuppress > 0 {
                dirty = true
            }
        }
        
        if vDirty {
            vDirty = false
            updateV()
        }
    }
    
    private func updateV() {
        if scanline >= 240 || !renderingEnabled {
            v = (v + control.verticalIncrement) & 0x7fff
            busAddress = v & 0x3fff
        } else {
            incHorizontalScroll()
            incVerticalScroll()
        }
    }
    
    enum CodingKeys: CodingKey {
        case dot
        case scanline
        case latch
        case frameBuffer
        case control
        case mask
        case status
    }
}

