import SwiftUI

/// Environment key for open media
struct ErrorEnv: EnvironmentKey {
    typealias Value = ErrorAction

    static var defaultValue: ErrorAction {
        .init { _ in .discarded }
    }
}

/// Environments values integration for custom values
extension EnvironmentValues {
    var error: ErrorAction {
        get { self[ErrorEnv.self] }
        set { self[ErrorEnv.self] = newValue }
    }
}

struct ErrorAction {
    enum Result {
        case discarded
        case handled
    }

    private let handler: (XemuError) -> Result

    init(handler: @escaping (XemuError) -> Result) {
        self.handler = handler
    }

    func callAsFunction(_ item: XemuError) {
        _ = handler(item)
    }
}

