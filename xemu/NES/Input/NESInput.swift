import Observation
import XemuFoundation
import SwiftUI

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
    
    func isPressed(_ key: NESInputKey) -> Bool {
        pressed.contains(key)
    }

    func binding(for key: NESInputKey) -> Binding<Bool> {
        Binding(
            get: { [weak self] in
                self?.pressed.contains(key) ?? false
            },
            set: { [weak self] value in
                if value {
                    self?.keyDown(key)
                } else {
                    self?.keyUp(key)
                }
            }
        )
    }
}
