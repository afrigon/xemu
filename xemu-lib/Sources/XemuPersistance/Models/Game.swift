import Foundation
import SwiftData
import XemuCore

@Model
public class Game {
    @Attribute(.unique) public var id: String
    public var name: String
    public var artwork: Data?
    public var data: Data
    @Attribute public private(set) var _console: String

    @Transient public var console: ConsoleType {
        get {
            ConsoleType(rawValue: _console)!
        }
        set {
            _console = newValue.rawValue
        }
    }

    public init(identifier: XemuIdentifier, name: String, data: Data, console: ConsoleType) {
        self.id = identifier.value
        self.name = name
        self.data = data
        self._console = console.rawValue
    }
}
