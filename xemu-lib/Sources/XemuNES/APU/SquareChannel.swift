import XemuFoundation

struct SquareChannel: Codable {
    var duty: u8 = 0b0000_0001
    var sequencer: u8 = 0
    var period: u16 = 0
    var timer: u16 = 0

    var sweep: Sweep
    var envelope: Envelope = .init()
    var lengthCounter: LengthCounter = .init()
    
    static let dutyTable: [u8] = [
        0b0100_0000,
        0b0110_0000,
        0b0111_1000,
        0b1001_1111
    ]
    
    init(_ index: Sweep.Index) {
        sweep = .init(index)
    }

    mutating func clock() {
        guard timer == 0 else {
            return timer -= 1
        }
        
        timer = period
        
        if sequencer == 0 {
            sequencer = 7
        } else {
            sequencer -= 1
        }
    }
    
    func output() -> u8 {
        guard lengthCounter.value > 0 else {
            return 0
        }
        
        return if sweep.targetPeriod(period) > 0x7FF || period < 8 {
            0
        } else {
            ((duty >> sequencer) & 1) * envelope.value
        }
    }
    
    mutating func clockSweep() {
        let targetPeriod = sweep.targetPeriod(period)
        
        if sweep.enabled && sweep.divider == 0 && sweep.shift != 0 && targetPeriod <= 0x7FF && period >= 8 {
            period = targetPeriod
        }
        
        if sweep.divider == 0 || sweep.reload {
            sweep.divider = sweep.period
            sweep.reload = false
        } else {
            sweep.divider -= 1
        }
    }
}
