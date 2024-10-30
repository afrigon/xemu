import MetalKit
import SwiftUI
import Combine

struct MetalView: UIViewRepresentable {
    class Coordinator: NSObject, MTKViewDelegate {
        let parent: MetalView
        let onUpdate: (TimeInterval) -> Void
        let onDraw: (MTKView) -> Void
        var time: TimeInterval = CACurrentMediaTime()

        init(
            _ parent: MetalView,
            onUpdate: @escaping (TimeInterval) -> Void,
            onDraw: @escaping (MTKView) -> Void
        ) {
            self.parent = parent
            self.onUpdate = onUpdate
            self.onDraw = onDraw
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

        func draw(in view: MTKView) {
            let currentTime = CACurrentMediaTime()
            let delta = currentTime - time
            
            onUpdate(delta)
            
            time = currentTime
            
            onDraw(view)
        }
        
    }
    
    @Binding var isRunning: Bool
    
    let onSetup: (MTKView) -> Void
    let onUpdate: (TimeInterval) -> Void
    let onDraw: (MTKView) -> Void
    
    init(
        isRunning: Binding<Bool>,
        onSetup: @escaping (MTKView) -> Void,
        onUpdate: @escaping (TimeInterval) -> Void,
        onDraw: @escaping (MTKView) -> Void
    ) {
        self._isRunning = isRunning
        self.onSetup = onSetup
        self.onUpdate = onUpdate
        self.onDraw = onDraw
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onUpdate: onUpdate, onDraw: onDraw)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        onSetup(view)
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        if uiView.isPaused, isRunning {
            context.coordinator.time = CACurrentMediaTime()
        }
            
        uiView.isPaused = !isRunning
    }
}
