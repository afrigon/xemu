import XemuFoundation

class APU: Codable {
    weak var bus: Bus!
    
    // TODO: no clue what these do but they are here to make the interrupt test pass
    var frameSequencerMode: u8 = 0
    var frameSequencer: u16 = 0
    var frameResetDelay: u8 = 0
    var quarterFrameCounter: u32 = 0
    var halfFrameCounter: u32 = 0
    
    var disableInterrupt: Bool = false
    var frameInterrupt: Bool = false
    
    init(bus: Bus) {
        self.bus = bus
    }
    
    func read(at address: u16) -> u8 {
        return 0
    }
    
    func write(_ data: u8, at address: u16) {
        switch address {
            case 0x4017:
                disableInterrupt = Bool(data & 0b0100_0000)
                
                // TODO: add whatever other things goes here
                
                if disableInterrupt {
                    frameInterrupt = false
                }
            default:
                break
        }
    }
    
    func clockFrameSequencer() {
        if frameSequencerMode == 0 {
            switch frameSequencer {
                case 29828:
                    if !disableInterrupt {
                        frameInterrupt = true
                    }
                case 29829:
                    if !disableInterrupt {
                        frameInterrupt = true
                    }
                case 29830:
                    if !disableInterrupt {
                        frameInterrupt = true
                    }
                    
                    frameSequencer = 0
                default:
                    break
            }
        } else {
            switch frameSequencer {
                case 37282:
                    frameSequencer = 0
                default:
                    break
            }
        }
        
        frameSequencer += 1
    }

    func clock() {
        clockFrameSequencer()
    }
    
    // TODO: update this with all the keys when done implementing apu
    enum CodingKeys: CodingKey {
        case frameSequencerMode
        case frameSequencer
        case frameResetDelay
        case quarterFrameCounter
        case halfFrameCounter
        case disableInterrupt
        case frameInterrupt
    }
}
