import XemuFoundation

struct ClockActions {
    var shouldClockCpu: Bool = false
    var shouldClockPpu: Bool = false
    var shouldClockApu: Bool = false
}

protocol Clock {
    var frequency: Int { get }
    var cpuFrequency: Int { get }
    var ppuFrequency: Int { get }
    var apuFrequency: Int { get }

    func clock() -> ClockActions
}

final class ClockNTSC: Clock {
    public let frequency = 21477272
    
    public var cpuFrequency: Int {
        frequency / Int(cpuDivider)
    }
    
    public var ppuFrequency: Int {
        frequency / Int(ppuDivider)
    }
    
    public var apuFrequency: Int {
        frequency / Int(apuDivider)
    }

    let cpuDivider: u8 = 12
    let ppuDivider: u8 = 4
    let apuDivider: u8 = 12
    
    private var cpuPhase: u8 = 0
    private var ppuPhase: u8 = 0
    private var apuPhase: u8 = 0

    func clock() -> ClockActions {
        cpuPhase += 1
        ppuPhase += 1
        apuPhase += 1
        
        var actions = ClockActions()
        
        if cpuPhase == cpuDivider {
            cpuPhase = 0
            actions.shouldClockCpu = true
        }
        
        if ppuPhase == ppuDivider {
            ppuPhase = 0
            actions.shouldClockPpu = true
        }
        
        if apuPhase == apuDivider {
            apuPhase = 0
            actions.shouldClockApu = true
        }

        return actions
    }
}
