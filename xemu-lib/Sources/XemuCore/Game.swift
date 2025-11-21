//import Foundation
//import SwiftData
//
//@Model
//public class Game {
//    @Attribute(.unique) public var id: String
//    public var name: String
//    public var artwork: Data?
//    public var data: Data
//    public var lastPlayedDate: Date? = nil
//    
//    @Attribute public private(set) var _system: String
//    @Transient public var system: SystemType {
//        get {
//            SystemType(rawValue: _system)!
//        }
//        set {
//            _system = newValue.rawValue
//        }
//    }
//    
//    @Relationship(deleteRule: .cascade, inverse: \GameSave.game)
//    public var saves: [GameSave] = []
//    
//    public var currentSave: UUID? = nil
//    
//    @Transient public var save: GameSave? {
//        guard let currentSave else {
//            return nil
//        }
//        
//        return saves.first(where: { $0.id == currentSave })
//    }
//
//    public init(identifier: XemuIdentifier, name: String, data: Data, system: SystemType) {
//        self.id = identifier.value
//        self.name = name
//        self.data = data
//        self._system = system.rawValue
//    }
//}
