/// https://nesdev.org/apu_ref.txt

import XemuFoundation
import XemuCore
import XKit

enum FrameSequencerMode: Codable {
    case fourStep
    case fiveStep
}

class APU: Codable {
    weak var bus: Bus!
    
    private let frequency: Int
    private let sampleRate: f64
    private var cycles: u64 = 0
    private var sampleCount: u64 = 0
    private var nextSample: u64

    private var accumulator: [f32] = []
    private var stagingBuffer: RingBuffer<f32>
    private var sampleBuffer: [f32]
    private var bufferFull = false

    var buffer: [f32]? {
        var buffer: [f32] = []
        
        if bufferFull {
            buffer = sampleBuffer
        }
        
        for i in 0..<stagingBuffer.index {
            buffer.append(stagingBuffer.buffer[i])
        }
        
        stagingBuffer.reset()
        bufferFull = false

        return buffer
    }

    var frameInterrupt: Bool = false
    var disableInterrupt: Bool = false

    var frameSequencer: u16 = 0
    var frameSequencerMode: FrameSequencerMode = .fourStep

    var square1: SquareChannel = .init(.square1)
    var square2: SquareChannel = .init(.square2)
    var triangle: TriangleChannel = .init()
    var noise: NoiseChannel = .init()
    var dmc: DeltaModulationChannel = .init()

    init(bus: Bus, frequency: Int = 1789773, sampleRate: f64 = 44100) {
        self.bus = bus
        self.frequency = frequency
        self.sampleRate = sampleRate
        self.stagingBuffer = .init(repeating: 0, count: APU.bufferSize(for: sampleRate))
        self.sampleBuffer = .init(repeating: 0, count: APU.bufferSize(for: sampleRate))
        
        nextSample = u64((f64(frequency) / sampleRate))
    }
    
    func reset(type: ResetType) {
        // TODO: implement this properly
        bus.write(0x00, at: 0x4015)
    }
    
    static func bufferSize(for sampleRate: Double) -> Int {
        let sampleCount = Int(sampleRate / 60) // samples per frame
        
        var size = 1
        
        while size < sampleCount {
            size *= 2
        }
        
        return size
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
    
    func debugRead() -> u8 {
        var status: u8 = 0
        
        if square1.lengthCounter.value > 0 {
            status |= 0b0000_0001
        }

        if square2.lengthCounter.value > 0 {
            status |= 0b0000_0010
        }
        
        if triangle.lengthCounter.value > 0 {
            status |= 0b0000_0100
        }
        
        if noise.lengthCounter.value > 0 {
            status |= 0b0000_1000
        }
        
        // dmc
        
        if frameInterrupt {
            status |= 0b0100_0000
        }
        
        return status
    }

    func read() -> u8 {
        var status: u8 = 0
        
        if square1.lengthCounter.value > 0 {
            status |= 0b0000_0001
        }

        if square2.lengthCounter.value > 0 {
            status |= 0b0000_0010
        }
        
        if triangle.lengthCounter.value > 0 {
            status |= 0b0000_0100
        }
        
        if noise.lengthCounter.value > 0 {
            status |= 0b0000_1000
        }
        
        // dmc
        
        if frameInterrupt {
            status |= 0b0100_0000
        }
        
        // dmc interrupt
        
        frameInterrupt = false
        bus.setIRQ(false)
        
        return status
    }

    func write(_ data: u8, at address: u16) {
        switch address {
            case 0x4000:
                let bit5 = Bool(data & 0b0010_0000)
                square1.duty = SquareChannel.dutyTable[Int(data >> 6)]
                square1.lengthCounter.halted = bit5
                square1.envelope.loop = bit5
                square1.envelope.enabled = !Bool(data & 0b0001_0000)
                square1.envelope.volume = data & 0b0000_1111
            case 0x4004:
                let bit5 = Bool(data & 0b0010_0000)
                square2.duty = SquareChannel.dutyTable[Int(data >> 6)]
                square2.lengthCounter.halted = bit5
                square2.envelope.loop = bit5
                square2.envelope.enabled = !Bool(data & 0b0001_0000)
                square2.envelope.volume = data & 0b0000_1111
            case 0x4001:
                square1.sweep.enabled = Bool(data & 0b1000_0000)
                square1.sweep.period = (data & 0b0111_0000) >> 4
                square1.sweep.negate = Bool(data & 0b0000_1000)
                square1.sweep.shift = data & 0b0000_0111
                square1.sweep.reload = true
            case 0x4005:
                square2.sweep.enabled = Bool(data & 0b1000_0000)
                square2.sweep.period = (data & 0b0111_0000) >> 4
                square2.sweep.negate = Bool(data & 0b0000_1000)
                square2.sweep.shift = data & 0b0000_0111
                square2.sweep.reload = true
            case 0x4002:
                square1.period = (square1.period & 0b111_0000_0000) | u16(data)
            case 0x4006:
                square2.period = (square2.period & 0b111_0000_0000) | u16(data)
            case 0x4003:
                square1.lengthCounter.load(data >> 3)
                square1.period = (square1.period & 0b000_1111_1111) | u16(data & 0b111) << 8
                square1.sequencer = 0
                square1.envelope.start = true
            case 0x4007:
                square2.lengthCounter.load(data >> 3)
                square2.period = (square2.period & 0b000_1111_1111) | u16(data & 0b111) << 8
                square2.sequencer = 0
                square2.envelope.start = true
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
            case 0x400C:
                let bit5 = Bool(data & 0b0010_0000)
                noise.lengthCounter.halted = bit5
                noise.envelope.loop = bit5
                noise.envelope.enabled = !Bool(data & 0b0001_0000)
                noise.envelope.volume = data & 0b0000_1111
            case 0x400E:
                noise.mode = Bool(data & 0b1000_0000)
                noise.period = NoiseChannel.periods[Int(data & 0b0000_1111)]
            case 0x400F:
                noise.lengthCounter.load(data >> 3)
                noise.envelope.start = true
            case 0x4015:
                // TODO: run ?
                
                bus.setIRQ(false)
                
                square1.lengthCounter.enabled = Bool(data & 0b0000_0001)
                square2.lengthCounter.enabled = Bool(data & 0b0000_0010)
                triangle.lengthCounter.enabled = Bool(data & 0b0000_0100)
                noise.lengthCounter.enabled = Bool(data & 0b0000_1000)
//                dmc.lengthCounter.enabled = Bool(data & 0b0001_0000)
            case 0x4017:
                disableInterrupt = Bool(data & 0b0100_0000)
                frameSequencerMode = (data & 0b1000_0000) == 0 ? .fourStep : .fiveStep
                frameSequencer = 0
                frameInterrupt = false
                bus.setIRQ(false)
                
                if frameSequencerMode == .fiveStep {
                    clockQuarterFrame()
                    clockHalfFrame()
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
                    case 29829:
                        clockQuarterFrame()
                        clockHalfFrame()
                        
                        if !disableInterrupt {
                            frameInterrupt = true
                            bus.setIRQ(true)
                        }
                        
                    case 29830:
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
                    case 29829:
                        clockQuarterFrame()
                        clockHalfFrame()
                    case 37281:
                        clockQuarterFrame()
                    case 37282:
                        frameSequencer = 0
                    default:
                        break
                }
        }
        
        frameSequencer += 1
    }

    func clockHalfFrame() {
        square1.lengthCounter.clock()
        square2.lengthCounter.clock()
        triangle.lengthCounter.clock()
        noise.lengthCounter.clock()
        
        square1.clockSweep()
        square2.clockSweep()
    }

    func clockQuarterFrame() {
        square1.envelope.clock()
        square2.envelope.clock()
        triangle.clockLinearCounter()
        noise.envelope.clock()
    }

    func step() {
        clockFrameSequencer()

        if cycles & 1 == 0 {
            square1.clock()
            square2.clock()
        }
        
        triangle.clock()
        noise.clock()

        accumulator.append(sample())

        if cycles >= nextSample {
            stagingBuffer.push(accumulator.reduce(0, +) / f32(accumulator.count))
            accumulator.removeAll(keepingCapacity: true)

            if stagingBuffer.index == 0 {
                sampleBuffer = stagingBuffer.buffer
                bufferFull = true
            }
            
            sampleCount &+= 1
            nextSample = ((sampleCount + 1) * u64(frequency)) / u64(sampleRate)
        }
        
        cycles &+= 1
    }

    func sample() -> f32 {
        let square1 = square1.output()
        let square2 = square2.output()
        let triangle = triangle.output()
        let noise = noise.output()
        let dmc = 0

        let square = squareTable[Int(square1 + square2)]
        let tnd = tndTable[tndIndex(t: u8(triangle), n: u8(noise), d: u8(dmc))]
        
        return ((square + tnd) * 2 - 1) * 0.2
    }

    // TODO: update this with all the keys when done implementing apu
    enum CodingKeys: String, CodingKey {
        case cycles
        case nextSample
        case sampleCount
        case frequency
        case sampleRate
        case accumulator
        case stagingBuffer
        case sampleBuffer
        case bufferFull
        case frameInterrupt
        case disableInterrupt
        case frameSequencer
        case frameSequencerMode
        case square1
        case square2
        case triangle
        case noise
    }
}
