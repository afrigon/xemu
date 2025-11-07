import Foundation
import XemuFoundation

final class PPU: Codable {
    private var dot: Int = 340
    private var scanline: Int = -1

    private var latch: u8 = 0
    
    private var control: PPUControlRegister = .init()
    private var mask: PPUMaskRegister = .init()
    private var status: PPUStatusRegister = .init()
    private var supressVBlank: Bool = false

    private var dirty: Bool = false
    private var renderingEnabled: Bool = true
    private var oldRenderingEnabled: Bool = true

    var frameCount: Int = 0
    private var frameBuffer: [u8] = .init(repeating: 0, count: 256 * 240)
    
    var frame: [u8] {
        frameBuffer
    }
    
    weak var bus: Bus!

    init(bus: Bus) {
        self.bus = bus
    }
    
    private func setControl(_ data: u8) {
        // TODO: set missing stuff
        
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
        
        if renderingEnabled != mask.backgroundEnabled || mask.spritesEnabled {
            dirty = true
        }
    }

    func read(at address: u16) -> u8 {
        switch address & 7 {
            case 2:
                let value = status.value
                
                // TODO: write toggle to false ?
                
                status.verticalBlank = false
                bus.setNMI(false)
                
                if scanline == 241 && dot == 0 {
                    supressVBlank = true
                }
                
                // TODO: update latch with mask
                
                return value
            case 4:
                return latch
            case 7:
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
                break
            case 6:  // PPUADDR
                break
            case 7:  // PPUDATA
                break
            default:
                break
        }
    }
    
    private func drawPixel() {
        frameBuffer[(scanline << 8) + dot - 1] = (0..<0x40).randomElement() ?? 0
//        if renderingEnabled || (v & 0x3f00) != 0x3f00 {
//            
//        } else {
//            frameBuffer[(scanline << 8) + dot - 1] = ?
//        }
    }
    
    private func firstCycle() {
        dot = 0
        scanline += 1
        
        if scanline > 260 {
            scanline = -1
        }
        
        if scanline < 240 {
            
        } else if scanline == 240 {
            frameCount += 1
        }
    }
    
    private func processScanline() {
        if dot <= 256 {
            if scanline < 0 {
                if dot == 1 {
                    status.verticalBlank = false
                    bus.setNMI(false)
                }
            } else {
                drawPixel()
            }
        }
    }

    func clock() {
        if dot < 340 {
            dot += 1
            
            if scanline < 240 {
                processScanline()
            } else if dot == 1 && scanline == 241 {
                if !supressVBlank {
                    status.verticalBlank = true
                    bus.setNMI(true)
                }
                
                supressVBlank = false
            }
        } else {
            firstCycle()
        }
        
        if dirty {
            update()
        }
    }
    
    private func update() {
        dirty = false
        
        // emulates the 1 cycle delay when enabling/disabling rendering
        if renderingEnabled != oldRenderingEnabled {
            oldRenderingEnabled = renderingEnabled
        }
        
        let newRenderingEnabled = mask.backgroundEnabled || mask.spritesEnabled
        if renderingEnabled != newRenderingEnabled {
            renderingEnabled = newRenderingEnabled
            dirty = true
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
