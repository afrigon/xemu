import Foundation
import SwiftData
import XemuCore

@Model
public class Game {
    @Attribute(.unique) public var id: String
    public var name: String
    public var artwork: Data?
    public var data: Data
    public var lastPlayedDate: Date? = nil
    
    @Attribute public private(set) var _system: String
    @Transient public var system: SystemType {
        get {
            SystemType(rawValue: _system)!
        }
        set {
            _system = newValue.rawValue
        }
    }

    public init(identifier: XemuIdentifier, name: String, data: Data, system: SystemType) {
        self.id = identifier.value
        self.name = name
        self.data = data
        self._system = system.rawValue
    }
}
