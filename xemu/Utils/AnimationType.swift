import SwiftUI

enum AnimationType {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case bouncy
    
    func animation(duration: Double) -> Animation {
        switch self {
            case .linear:
                .linear(duration: duration)
            case .easeIn:
                .easeIn(duration: duration)
            case .easeOut:
                .easeOut(duration: duration)
            case .easeInOut:
                .easeInOut(duration: duration)
            case .bouncy:
                .bouncy(duration: duration)
        }
    }
}

extension Animation {
    static func linear(_ speed: AnimationSpeed) -> Animation {
        .linear(duration: speed.rawValue)
    }
    
    static func easeIn(_ speed: AnimationSpeed) -> Animation {
        .easeIn(duration: speed.rawValue)
    }
    
    static func easeOut(_ speed: AnimationSpeed) -> Animation {
        .easeOut(duration: speed.rawValue)
    }
    
    static func easeInOut(_ speed: AnimationSpeed) -> Animation {
        .easeInOut(duration: speed.rawValue)
    }
    
    static func bouncy(_ speed: AnimationSpeed) -> Animation {
        .bouncy(duration: speed.rawValue)
    }
    
    @MainActor
    static func animate(_ animation: AnimationType, duration: AnimationSpeed = .default, _ body: () -> Void) async {
        await withCheckedContinuation { continuation in
            withAnimation(animation.animation(duration: duration.rawValue)) {
                body()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration.rawValue) {
                continuation.resume()
            }
        }
    }
}
