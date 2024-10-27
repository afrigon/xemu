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
    /// - note: After power/reset, writes to this register are ignored until the first pre-render scanline
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
    
    private func drawPixel() {
        frameBuffer[256 * scanline + dot - 1] = (0..<64).randomElement()!
    }
    
    private func render() {
        switch dot {
            case 1...256:
                drawPixel()
            default:
                break
        }
    }
    
    private func vblank() {
        if dot == 1 {
            status |= 0b1000_0000
            needsRender = true
        }
    }
    
    private func prerender() {
        switch dot {
            case 1:
                status &= 0b0111_1111
            default:
                break
        }
    }

    func clock() {
        switch scanline {
            case 0..<240:
                render()
            case 241:
                vblank()
            case 261:
                prerender()
            default:
                break
        }
        
        dot += 1
        if dot >= 340 {
            dot = 0
            scanline += 1
            
            if scanline > 261 {
                scanline = 0
                isOddFrame.toggle()
            }
        }
    }
    
    enum CodingKeys: CodingKey {
        case control
        case status
        case scanline
    }
}
