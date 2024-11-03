import Foundation
import XemuCore
import XemuDebugger
import XemuFoundation

class AppContext {
    var emulator: (any Emulator & Debuggable)? = nil
    var program: Data? = nil
    var breakpoints: [Breakpoint] = []
    var windows: [SwiftUIWindow] = []
}
