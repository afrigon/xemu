@testable import XemuNES
import Testing

@MainActor
struct PPUTests {
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_vbl_basics() async throws {
        try TestHelper.testBlargg(test: "ppu_01-vbl_basics")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_vbl_set_time() async throws {
        try TestHelper.testBlargg(test: "ppu_02-vbl_set_time")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_vbl_clear_time() async throws {
        try TestHelper.testBlargg(test: "ppu_03-vbl_clear_time")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_nmi_control() async throws {
        try TestHelper.testBlargg(test: "ppu_04-nmi_control")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_nmi_timing() async throws {
        try TestHelper.testBlargg(test: "ppu_05-nmi_timing")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_suppression() async throws {
        try TestHelper.testBlargg(test: "ppu_06-suppression")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_nmi_on_timing() async throws {
        try TestHelper.testBlargg(test: "ppu_07-nmi_on_timing")
    }
    
    @Test(.timeLimit(.minutes(2))) func blargg_ppu_nmi_off_timing() async throws {
        try TestHelper.testBlargg(test: "ppu_08-nmi_off_timing")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_even_odd_frames() async throws {
        try TestHelper.testBlargg(test: "ppu_09-even_odd_frames")
    }
    
    @Test(.timeLimit(.minutes(1))) func blargg_ppu_even_odd_timing() async throws {
        try TestHelper.testBlargg(test: "ppu_10-even_odd_timing")
    }
}

