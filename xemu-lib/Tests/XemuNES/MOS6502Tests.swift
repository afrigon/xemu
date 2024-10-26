@testable import XemuNES
import Testing
import Foundation
import XemuFoundation
import XemuAsm

@MainActor
struct MOS6502Tests {
    func testBlargg(test: String, debug: Bool = false) throws {
        let nes = try TestData.loadMockSystem(with: "blargg_\(test)")
        let magic: [u8] = [0xDE, 0xB0, 0x61]
        var status: u8? = nil
        
        while status == 0x80 || status == 0x81 || status == nil {
            if status == 0x81 {
                // run for 100ms
                for _ in 0..<179000 {
                    try nes.clock()
                }
                
                // finish potential incomplete instruction
                try nes.stepi()

                nes.reset()
            }
            
            try nes.stepi()
            
            if status == nil {
                if nes.getMemory(in: 0x6001..<0x6004) == magic {
                    status = nes.bus.read(at: 0x6000)
                }
            } else {
                status = nes.bus.read(at: 0x6000)
            }
            
            if debug {
                print(nes.status)
            }
        }

        print(nes.bus.readString(at: 0x6004))
        #expect(nes.bus.read(at: 0x6000) == 0x00)
    }
    
    @Test(.timeLimit(.minutes(1))) func nestest() async throws {
        // the nestest rom has been modified, the reset vector points to 0xC000
        let nes = try TestData.loadMockSystem(with: "nestest")
        
        while true {
            repeat {
                try nes.clock()
            } while nes.cpu.state.tick != 0
            
            if nes.cpu.registers.s > 0xFD {
                break
            }
        }
        
        #expect(nes.bus.read(at: 0x02) == 0x00)
        #expect(nes.bus.read(at: 0x03) == 0x00)
        #expect(nes.cycles == 26560)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_registers_reset() async throws {
        try testBlargg(test: "registers_reset")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ram_reset() async throws {
        try testBlargg(test: "ram_reset")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_basics() async throws {
        try testBlargg(test: "01-basics")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_implied() async throws {
        try testBlargg(test: "02-implied")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_immediate() async throws {
        try testBlargg(test: "03-immediate")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_zero_page() async throws {
        try testBlargg(test: "04-zero_page")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_zero_page_indexed() async throws {
        try testBlargg(test: "05-zp_xy")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_absolute() async throws {
        try testBlargg(test: "06-absolute")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_absolute_indexed() async throws {
        try testBlargg(test: "07-abs_xy")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_indexed_indirect_x() async throws {
        try testBlargg(test: "08-ind_x")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_indirect_indexed_y() async throws {
        try testBlargg(test: "09-ind_y")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_branches() async throws {
        try testBlargg(test: "10-branches")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_stack() async throws {
        try testBlargg(test: "11-stack")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_jmp_jsr() async throws {
        try testBlargg(test: "12-jmp_jsr")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_rts() async throws {
        try testBlargg(test: "13-rts")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_rti() async throws {
        try testBlargg(test: "14-rti")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_brk() async throws {
        try testBlargg(test: "15-brk")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_special() async throws {
        try testBlargg(test: "16-special")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_cpu_timing() async throws {
        try testBlargg(test: "cpu_timing")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_cpu_interrupts() async throws {
        try testBlargg(test: "cpu_interrupts")
    }
}

