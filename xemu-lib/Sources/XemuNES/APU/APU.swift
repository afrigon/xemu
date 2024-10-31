import XemuFoundation

enum FrameSequencerMode: Codable {
    case fourStep
    case fiveStep
}

class APU: Codable {
    weak var bus: Bus!
    
    private var bufferReady = false
    
    private var stagingIndex: Int = 0
    private var stagingBuffer: [Float] = .init(repeating: 0, count: 40)
    
    private var sampleIndex: Int = 0
    private var sampleBuffer: [Float] = .init(repeating: 0, count: 1024)
    
    var buffer: [Float]? {
        guard bufferReady else {
            return nil
        }
        
        bufferReady = false
        
        return sampleBuffer
    }
    
    var disableInterrupt: Bool = false
    
    var frameSequencer: u16 = 0
    var frameSequencerMode: FrameSequencerMode = .fourStep
    
    var triangle: TriangleChannel = .init()
    
    init(bus: Bus) {
        self.bus = bus
    }
    
    lazy var squareTable: [Float] = {
        (0...30).map {
            95.88 / (8128.0 / Float($0) + 100)
        }
    }()
    
    lazy var tndTable: [Float] = {
        var data: [Float] = .init(repeating: 0, count: 16 * 16 * 128)
        
        for t in 0...15 {
            for n in 0...15 {
                for d in 0...127 {
                    data[tndIndex(t: u8(t), n: u8(n), d: u8(d))] = 159.79 / (1 / (Float(t) / 8227 + Float(n) / 12241 + Float(d) / 22638) + 100)
                }
            }
        }
            
        return data
    }()
    
    func tndIndex(t: u8, n: u8, d: u8) -> Int {
        Int(d) * 16 * 16 + Int(n) * 16 + Int(t)
    }

    func read(at address: u16) -> u8 {
        return 0
    }
    
    func write(_ data: u8, at address: u16) {
        switch address {
            case 0x4008:
                let control = Bool(data & 0b1000_0000)
                triangle.control = control
                triangle.lengthCounter.halted = control
                triangle.linearCounterReload = data & 0b0111_1111
            case 0x400A:
                triangle.period = (triangle.timer & 0b111_0000_0000) | u16(data)
            case 0x400B:
                triangle.lengthCounter.load(data >> 3)
                triangle.timer = (triangle.timer & 0b000_1111_1111) | u16(data & 0b111) << 8
                triangle.linearCounterReloadFlag = true
            case 0x4017:
                disableInterrupt = Bool(data & 0b0100_0000)
                frameSequencerMode = (data & 0b1000_0000) == 0 ? .fourStep : .fiveStep
                frameSequencer = 0

                // TODO: add whatever other things goes here
                
                if disableInterrupt {
                    bus.requestIRQ()
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
                            bus.requestIRQ()
                        }
                    case 29829:
                        if !disableInterrupt {
                            bus.requestIRQ()
                        }
                        
                        clockQuarterFrame()
                        clockHalfFrame()
                    case 29830:
                        if !disableInterrupt {
                            bus.requestIRQ()
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
        
        if stagingIndex == 39 {
            sampleBuffer[sampleIndex] = stagingBuffer.reduce(0, +) / 40
            stagingIndex = 0
            sampleIndex += 1
            
            if sampleIndex == 1023 {
                sampleIndex = 0
                bufferReady = true
            }
        }
    }
    
    func sample() -> Float {
        let square1 = 1
        let square2 = 1
        let triangle = triangle.output()
        let noise = 1
        let dmc = 1
        
        let square = squareTable[Int(square1 + square2)]
        let tnd = tndTable[tndIndex(t: u8(triangle), n: u8(noise), d: u8(dmc))]
        
        return square + tnd
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
import Foundation
import QuartzCore
