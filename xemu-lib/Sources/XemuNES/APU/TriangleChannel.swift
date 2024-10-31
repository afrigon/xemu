import XemuFoundation

struct TriangleChannel: Codable {
    var control: Bool = false

    var linearCounter: u8 = 0
    var linearCounterReload: u8 = 0
    var linearCounterReloadFlag: Bool = false

    var lengthCounter: LengthCounter = .init()

    var sequencer: u8 = 0
    var period: u16 = 0
    var timer: u16 = 0

    mutating func clockLinearCounter() {
        if linearCounterReloadFlag {
            linearCounter = linearCounterReload
        } else {
            if linearCounter != 0 {
                linearCounter -= 1
            }
        }

        if !control {
            linearCounterReloadFlag = false
        }
    }

    mutating func clock() {
        guard linearCounter != 0 && lengthCounter.value != 0 else {
            return
        }

        if timer == 0 {
            timer = period

            sequencer = (sequencer + 1) % 32
        } else {
            timer -= 1
        }
    }

    func output() -> u8 {
        if period <= 2 {
            return 7
        }
        
        return if sequencer <= 15 {
            15 - sequencer
        } else {
            sequencer - 16
        }
    }
}
