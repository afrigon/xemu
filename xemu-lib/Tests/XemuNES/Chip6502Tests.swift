@testable import XemuNES
import Testing
import Foundation

@MainActor
struct Chip6502Tests {
    @Test(.timeLimit(.minutes(1))) func nestest() async throws {
        let nes = try TestData.loadMockSystem(with: "nestest")
        nes.cpu.pc = 0xc000
        
        while true {
            do {
                try nes.clock()
            } catch {
                break
            }
        }
        
        #expect(nes.bus.read(at: 0x02) == 0x00)
        #expect(nes.bus.read(at: 0x03) == 0x00)
    }
}

