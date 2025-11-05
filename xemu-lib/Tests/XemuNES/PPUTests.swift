@testable import XemuNES
import Testing

@MainActor
struct PPUTests {
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_vbl_basics() async throws {
        try TestHelper.testBlargg(test: "ppu_01-vbl_basics")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_vbl_set_time() async throws {
        try TestHelper.testBlargg(test: "ppu_02-vbl_set_time")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_vbl_clear_time() async throws {
        try TestHelper.testBlargg(test: "ppu_03-vbl_clear_time")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_nmi_control() async throws {
        try TestHelper.testBlargg(test: "ppu_04-nmi_control")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_nmi_timing() async throws {
        try TestHelper.testBlargg(test: "ppu_05-nmi_timing")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_suppression() async throws {
        try TestHelper.testBlargg(test: "ppu_06-suppression")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_nmi_on_timing() async throws {
        try TestHelper.testBlargg(test: "ppu_07-nmi_on_timing")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_nmi_off_timing() async throws {
        try TestHelper.testBlargg(test: "ppu_08-nmi_off_timing")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_even_odd_frames() async throws {
        try TestHelper.testBlargg(test: "ppu_09-even_odd_frames")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_even_odd_timing() async throws {
        try TestHelper.testBlargg(test: "ppu_10-even_odd_timing")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_open_bus() async throws {
        try TestHelper.testBlargg(test: "ppu_11-open_bus")
    }
    
    @Test(.timeLimit(.minutes(5))) func blargg_ppu_read_buffer() async throws {
        try TestHelper.testBlargg(test: "ppu_12-read_buffer")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_oam_read() async throws {
        try TestHelper.testBlargg(test: "ppu_13-oam_read")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_oam_stress() async throws {
        try TestHelper.testBlargg(test: "ppu_14-oam_stress")
    }
}

