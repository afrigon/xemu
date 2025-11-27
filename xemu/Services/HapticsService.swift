#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

class HapticsService {
    @MainActor static let shared = HapticsService()
    
#if canImport(UIKit)
    let generator: UIImpactFeedbackGenerator
    
    init(generator: UIImpactFeedbackGenerator = .init(style: .light)) {
        self.generator = generator
    }
#endif
    
    func impact(intensity: CGFloat = 1.0) {
#if canImport(UIKit)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
#endif
    }
}
