import AppKit
import SwiftUI

@MainActor
struct SwiftUIWindow {
    var window: NSWindow
    
    init(title: String, size: CGSize, content: () -> any View) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = title
        window.contentView = NSHostingView(rootView: AnyView(content()))
        
        self.window = window
    }
    
    public func show() {
        window.makeKeyAndOrderFront(nil)
    }
}
