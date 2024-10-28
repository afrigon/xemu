import Foundation
import Testing
import XemuNES
import XemuDebugger
import XemuFoundation

@MainActor
class TestHelper {
    static func loadROM(named name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "nes", subdirectory: "Data"))
        return try Data(contentsOf: url)
    }
    
    static func loadMockSystem(with name: String) throws -> MockSystem {
        let nes = MockSystem()
        
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "nes", subdirectory: "Data"))
        let data = try Data(contentsOf: url)
        
        try nes.load(program: data)
        nes.reset()
        
        return nes
    }
    
    static func loadSystem(with name: String) throws -> NES {
        let nes = NES()
        
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "nes", subdirectory: "Data"))
        let data = try Data(contentsOf: url)
        
        try nes.load(program: data)
        nes.reset()
        
        return nes
    }
    
    static func testBlargg(test: String, debug: Bool = false, mock: Bool = false) throws {
        let nes: Debuggable = if mock {
            try loadMockSystem(with: "blargg_\(test)")
        } else {
            try loadSystem(with: "blargg_\(test)")
        }
        
        let magic: [u8] = [0xDE, 0xB0, 0x61]
        var status: u8? = nil
        
        while status == 0x80 || status == 0x81 || status == nil {
//            if status == 0x81 {
//                print("resetting")
//
//                // run for 100ms
//                for _ in 0..<179000 {
//                    try nes.clock()
//                }
//
//                // finish potential incomplete instruction
//                try nes.stepi()
//
//                nes.reset()
//
//                try nes.stepi() // step the reset cycles
//            }
            
            try nes.stepi()
            
            if status == nil {
                if nes.getMemory(in: 0x6001...0x6003) == magic {
                    status = nes.getMemory(at: 0x6000)
                }
            } else {
                status = nes.getMemory(at: 0x6000)
            }
            
            if debug {
                print(nes.status)
            }
        }

        print(nes.getString(at: 0x6004))
        #expect(nes.getMemory(at: 0x6000) == 0x00)
    }
}
