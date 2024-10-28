import SwiftUI
import CoreVideo

class LoopModifierModel {
    let onUpdate: (Double) -> Void
    let fps: Float?
    
    private lazy var displayLink: CADisplayLink = {
#if os(macOS)
        let link = NSScreen.main!.displayLink(target: self, selector: #selector(update))
#else
        let link = CADisplayLink(target: self, selector: #selector(update))
#endif
        if let fps {
            link.preferredFrameRateRange = .init(minimum: 1, maximum: Float(fps))
        }
        
        return link
    }()
    
    init(onUpdate: @escaping (Double) -> Void, fps: Float? = nil) {
        self.onUpdate = onUpdate
        self.fps = fps
    }
    
    @objc private func update() {
        onUpdate(displayLink.duration)
    }
    
    func start() {
        displayLink.add(to: .main, forMode: .default)
    }
    
    func stop() {
        displayLink.invalidate()
    }
}

struct LoopModifier: ViewModifier {
    let model: LoopModifierModel
    
    init(onUpdate: @escaping (Double) -> Void, fps: Float? = nil) {
        model = .init(onUpdate: onUpdate, fps: fps)
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                model.start()
            }
            .onDisappear {
                model.stop()
            }
    }
}

extension View {
    func loop(fps: Float? = nil, onUpdate: @escaping (Double) -> Void) -> some View {
        modifier(LoopModifier(onUpdate: onUpdate, fps: fps))
    }
}
