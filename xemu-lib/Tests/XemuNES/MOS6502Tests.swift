@testable import XemuNES
import Testing
import Foundation
import XemuFoundation
import XemuAsm

@MainActor
struct MOS6502Tests {
    @Test(.timeLimit(.minutes(1))) func nestest() async throws {
        let nes = try TestData.loadMockSystem(with: "nestest")
        nes.cpu.registers.pc = 0xc000
        
        var cycles: Int = 7
        
        while true {
//            if let instruction = nes.disassemble(at: Int(nes.cpu.registers.pc), count: 1).first {
//                print(instruction.description, terminator: " ")
//                print("A:\(nes.cpu.registers.a.hex(toLength: 2, textCase: .uppercase))", terminator: " ")
//                print("X:\(nes.cpu.registers.x.hex(toLength: 2, textCase: .uppercase))", terminator: " ")
//                print("Y:\(nes.cpu.registers.y.hex(toLength: 2, textCase: .uppercase))", terminator: " ")
//                print("P:\(nes.cpu.registers.p.hex(toLength: 2, textCase: .uppercase))", terminator: " ")
//                print("SP:\(nes.cpu.registers.s.hex(toLength: 2, textCase: .uppercase))", terminator: " ")
//                print("CYC:\(cycles)")
//            }

            do throws(XemuError) {
                while true {
                    try nes.stepi()
                }
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

