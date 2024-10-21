@testable import XemuNES
import Testing
import Foundation
import XemuFoundation

@MainActor
struct Chip6502Tests {
    @Test(.timeLimit(.minutes(1))) func nestest() async throws {
        let nes = try TestData.loadMockSystem(with: "nestest")
        nes.cpu.pc = 0xc000
        
        var cycles: Int = 7
        
        while true {
            if let instruction = nes.disassemble(at: Int(nes.cpu.pc), count: 1).first {
                print(instruction.description, terminator: " ")
                print("A:\(nes.cpu.a.hex(prefix: "", padTo: 2, uppercase: true))", terminator: " ")
                print("X:\(nes.cpu.x.hex(prefix: "", padTo: 2, uppercase: true))", terminator: " ")
                print("Y:\(nes.cpu.y.hex(prefix: "", padTo: 2, uppercase: true))", terminator: " ")
                print("P:\(nes.cpu.p.hex(prefix: "", padTo: 2, uppercase: true))", terminator: " ")
                print("SP:\(nes.cpu.s.hex(prefix: "", padTo: 2, uppercase: true))", terminator: " ")
                print("CYC:\(cycles)")
            }

            do throws(XemuError) {
                repeat {
                    try nes.clock()
                    cycles += 1
                } while !nes.cpu.state.complete
            } catch let error {
                switch error {
                    case .notImplemented, .invalidState, .busDisconnected:
                        Issue.record(error, "finished in an invalid state")
                    default:
                        break
                }
                
                break
            }
        }
        
        #expect(nes.bus.read(at: 0x02) == 0x00)
        #expect(nes.bus.read(at: 0x03) == 0x00)
    }
}

