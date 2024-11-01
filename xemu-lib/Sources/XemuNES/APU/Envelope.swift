import XemuFoundation

struct Envelope: Codable {
    var enabled: Bool = false
    var start: Bool = false
    var loop: Bool = false
    var volume: u8 = 0
    var decay: u8 = 0
    var divider: u8 = 0
    
    var value: u8 {
        if enabled {
            decay
        } else {
            volume
        }
    }

    mutating func clock() {
        if start {
            start = false
            decay = 15
            divider = volume
        } else {
            guard divider == 0 else {
                return divider -= 1
            }
            
            divider = volume
            
            if decay > 0 {
                decay -= 1
            } else {
                if loop {
                    decay = 15
                }
            }
        }
    }
}
