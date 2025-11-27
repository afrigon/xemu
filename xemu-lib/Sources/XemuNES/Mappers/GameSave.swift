import Foundation

struct GameSave: Codable {
    var prg: Data?
    var chr: Data?
    let version: Int
    
    init() {
        version = 1
    }
}
