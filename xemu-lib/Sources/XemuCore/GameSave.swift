import Foundation
import SwiftData

@Model
public class GameSave {
    @Attribute(.unique) public var id: UUID
    public var created: Date
    public var lastUpdate: Date
    
    public var name: String
    
    public var data: Data
    public var screenshot: Data?
    
    public var game: Game

    public init(
        game: Game,
        data: Data,
        screenshot: Data?
    ) {
        self.id = UUID()
        
        let created = Date()
        self.created = created
        self.lastUpdate = created
        
        self.name = created.ISO8601Format()
        
        self.data = data
        self.screenshot = screenshot
        
        self.game = game
    }
}
