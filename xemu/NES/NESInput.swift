import Observation
import XemuFoundation

enum NESInputKey: u8 {
    case a = 1
    case b = 2
    case select = 4
    case start = 8
    case up = 16
    case down = 32
    case left = 64
    case right = 128
}

@Observable // TODO: remove this from here and use a generic input object.
class NESInput {
    private var pressed: Set<NESInputKey> = []
    
    func keyDown(_ key: NESInputKey) {
        pressed.insert(key)
    }
    
    func keyUp(_ key: NESInputKey) {
        pressed.remove(key)
    }

    func encode() -> u8 {
        pressed.reduce(0) { $0 | $1.rawValue }
    }
}
