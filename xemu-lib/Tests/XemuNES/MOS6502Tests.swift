@testable import XemuNES
import Testing

@MainActor
struct MOS6502Tests {
    @Test(.timeLimit(.minutes(1))) func nestest() async throws {
        // the nestest rom has been modified, the reset vector points to 0xC000
        let nes = try TestHelper.loadMockSystem(with: "nestest")
        
        print(nes.status)
        
        while true {
            try nes.stepi()
            
            if nes.cpu.registers.s > 0xFD {
                break
            }
            
            print(nes.status)
        }
        
        #expect(nes.bus.read(at: 0x02) == 0x00)
        #expect(nes.bus.read(at: 0x03) == 0x00)
        #expect(nes.cycles == 26560)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_basics() async throws {
        try TestHelper.testBlargg(test: "01-basics", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_implied() async throws {
        try TestHelper.testBlargg(test: "02-implied", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_immediate() async throws {
        try TestHelper.testBlargg(test: "03-immediate", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_zero_page() async throws {
        try TestHelper.testBlargg(test: "04-zero_page", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_zero_page_indexed() async throws {
        try TestHelper.testBlargg(test: "05-zp_xy", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_absolute() async throws {
        try TestHelper.testBlargg(test: "06-absolute", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_absolute_indexed() async throws {
        try TestHelper.testBlargg(test: "07-abs_xy", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_indexed_indirect_x() async throws {
        try TestHelper.testBlargg(test: "08-ind_x", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_indirect_indexed_y() async throws {
        try TestHelper.testBlargg(test: "09-ind_y", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_branches() async throws {
        try TestHelper.testBlargg(test: "10-branches", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_stack() async throws {
        try TestHelper.testBlargg(test: "11-stack", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_jmp_jsr() async throws {
        try TestHelper.testBlargg(test: "12-jmp_jsr", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_rts() async throws {
        try TestHelper.testBlargg(test: "13-rts", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_rti() async throws {
        try TestHelper.testBlargg(test: "14-rti", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_brk() async throws {
        try TestHelper.testBlargg(test: "15-brk", mock: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_instrs_special() async throws {
        try TestHelper.testBlargg(test: "16-special", mock: true)
    }

    @Test(.timeLimit(.minutes(4))) func blargg_instrs_timing() async throws {
        try TestHelper.testBlargg(test: "instrs_timing", debug: true)
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_branch_timing() async throws {
        try TestHelper.testBlargg(test: "branch_timing")
    }

    @Test(.timeLimit(.minutes(1))) func blargg_interrupts_cli_latency() async throws {
        try TestHelper.testBlargg(test: "interrupts_01-cli_latency")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_interrupts_nmi_and_brk() async throws {
        try TestHelper.testBlargg(test: "interrupts_02-nmi_and_brk")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_interrupts_nmi_and_irq() async throws {
        try TestHelper.testBlargg(test: "interrupts_03-nmi_and_irq")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_interrupts_irq_and_dma() async throws {
        try TestHelper.testBlargg(test: "interrupts_04-irq_and_dma")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_interrupts_branch_delays_irq() async throws {
        try TestHelper.testBlargg(test: "interrupts_05-branch_delays_irq")
    }
}

