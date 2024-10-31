import XemuFoundation

enum FrameSequencerMode: Codable {
    case fourStep
    case fiveStep
}

class APU: Codable {
    weak var bus: Bus!

    private var bufferReady = false

    private var stagingBuffer: [f32] = .init(repeating: 0, count: APU.stagingCount)
    private var stagingIndex: Int = 0
    private static let stagingCount: Int = 39

    private var sampleIndex: Int = 0
    private var sampleBuffer: [f32] = .init(repeating: 0, count: APU.sampleCount)
    private static let sampleCount: Int = 1024

    var buffer: [f32]? {
        guard bufferReady else {
            return nil
        }

        bufferReady = false

        return sampleBuffer
    }

    var frameInterrupt: Bool = false
    var disableInterrupt: Bool = false

    var frameSequencer: u16 = 0
    var frameSequencerMode: FrameSequencerMode = .fourStep

    var triangle: TriangleChannel = .init()

    init(bus: Bus) {
        self.bus = bus
    }

    lazy var squareTable: [f32] = {
        (0...30).map {
            95.88 / (8128.0 / f32($0) + 100)
        }
    }()

    lazy var tndTable: [f32] = {
        var data: [f32] = .init(repeating: 0, count: 16 * 16 * 128)

        for t in 0...15 {
            for n in 0...15 {
                for d in 0...127 {
                    data[tndIndex(t: u8(t), n: u8(n), d: u8(d))] = 159.79 / (1 / (f32(t) / 8227 + f32(n) / 12241 + f32(d) / 22638) + 100)
                }
            }
        }

        return data
    }()

    func tndIndex(t: u8, n: u8, d: u8) -> Int {
        Int(d) * 16 * 16 + Int(n) * 16 + Int(t)
    }

    func read() -> u8 {
        var status: u8 = 0
        
        // square 1
        // square 2
        
        if triangle.lengthCounter.value > 0 {
            status |= 0b0000_0100
        }
        
        // noise
        // dmc
        
        if frameInterrupt {
            status |= 0b0100_0000
        }
        
        // dmc intterupt
        
        frameInterrupt = false
        
        return status
    }

    func write(_ data: u8, at address: u16) {
        switch address {
            case 0x4008:
                let control = Bool(data & 0b1000_0000)
                triangle.control = control
                triangle.lengthCounter.halted = control
                triangle.linearCounterReload = data & 0b0111_1111
            case 0x400A:
                triangle.period = (triangle.period & 0b111_0000_0000) | u16(data)
            case 0x400B:
                triangle.lengthCounter.load(data >> 3)
                triangle.period = (triangle.period & 0b000_1111_1111) | u16(data & 0b111) << 8
                triangle.linearCounterReloadFlag = true
            case 0x4017:
                disableInterrupt = Bool(data & 0b0100_0000)
                frameSequencerMode = (data & 0b1000_0000) == 0 ? .fourStep : .fiveStep
                frameSequencer = 0

                if disableInterrupt {
                    frameInterrupt = true
                }
            default:
                break
        }
    }

    func clockFrameSequencer() {
        switch frameSequencerMode {
            case .fourStep:
                switch frameSequencer {
                    case 7457:
                        clockQuarterFrame()
                    case 14913:
                        clockQuarterFrame()
                        clockHalfFrame()
                    case 22371:
                        clockQuarterFrame()
                    case 29828:
                        if !disableInterrupt {
                            frameInterrupt = true
                        }
                    case 29829:
                        if !disableInterrupt {
                            frameInterrupt = true
                        }

                        clockQuarterFrame()
                        clockHalfFrame()
                    case 29830:
                        if !disableInterrupt {
                            frameInterrupt = true
                        }

                        frameSequencer = 0
                    default:
                        break
                }
            case .fiveStep:
                switch frameSequencer {
                    case 7457:
                        clockQuarterFrame()
                    case 14913:
                        clockQuarterFrame()
                        clockHalfFrame()
                    case 22371:
                        clockQuarterFrame()
                    case 37281:
                        clockQuarterFrame()
                        clockHalfFrame()
                    case 37282:
                        frameSequencer = 0
                    default:
                        break
                }
        }

        frameSequencer += 1
    }

    func clockHalfFrame() {

    }

    func clockQuarterFrame() {
        triangle.clockLinearCounter()
    }

    func clock() {
        clockFrameSequencer()

        triangle.clock()

        let value = sample()
        stagingBuffer[stagingIndex] = value
        stagingIndex += 1

        if stagingIndex == APU.stagingCount {
            sampleBuffer[sampleIndex] = stagingBuffer.reduce(0, +) / f32(APU.stagingCount)
            stagingIndex = 0
            sampleIndex += 1

            if sampleIndex == APU.sampleCount {
                sampleIndex = 0
                bufferReady = true
            }
        }
    }

    func sample() -> f32 {
//        let square1 = 1
//        let square2 = 1
//        let triangle = triangle.output()
//        let noise = 1
//        let dmc = 1
//
//        let square = squareTable[Int(square1 + square2)]
//        let tnd = tndTable[tndIndex(t: u8(triangle), n: u8(noise), d: u8(dmc))]
//
//        return square + tnd
        return (f32(triangle.output()) / 15)
    }

    // TODO: update this with all the keys when done implementing apu
    enum CodingKeys: String, CodingKey {
        case bufferReady
        case stagingIndex
        case stagingBuffer
        case sampleIndex
        case sampleBuffer
        case frameSequencer
        case frameSequencerMode
        case disableInterrupt
        case triangle
    }
}
