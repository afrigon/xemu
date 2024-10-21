import Foundation
import Testing
import XemuNES

@MainActor
class TestData {
    static func loadROM(named name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "nes", subdirectory: "Data"))
        return try Data(contentsOf: url)
    }
    
    static func loadMockSystem(with name: String) throws -> MockSystem {
        let nes = MockSystem()
        
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "nes", subdirectory: "Data"))
        let data = try Data(contentsOf: url)
        
        try nes.load(program: data)
        
        return nes
    }
}
