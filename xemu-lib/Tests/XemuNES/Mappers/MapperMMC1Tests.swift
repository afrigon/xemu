@testable import XemuNES
import Testing

@MainActor
struct MapperMMC1Tests {
    func createMapper() -> MapperMMC1 {
        .init(pgrrom: .init(count: 0), chrrom: .init(count: 0), sram: .init(count: 0))
    }
    
    @Test func registers_initial_state() async throws {
        let mapper = createMapper()
        
        #expect(mapper.shift == 0b1000_0000)
        #expect(mapper.control == 0x0C)
        #expect(mapper.chrbank0 == 0)
        #expect(mapper.chrbank1 == 0)
        #expect(mapper.pgrbank == 0)
    }
    
    @Test func consecutive_writes_are_ignored() async throws {
        let mapper = createMapper()
        
        mapper.cpuWrite(0x00, at: 0x8000)
        mapper.cpuWrite(0x00, at: 0x8000)
        
        #expect(mapper.shift == 0b0100_0000)
    }
    
    @Test func consecutive_writes_is_reset_by_read() async throws {
        let mapper = createMapper()
        
        mapper.cpuWrite(0x00, at: 0x8000)
        _ = mapper.cpuRead(at: 0x0000)
        mapper.cpuWrite(0x00, at: 0x8000)
        
        #expect(mapper.shift == 0b0010_0000)
    }

    @Test func consecutive_writes_is_triggered_from_outside_the_address_range() async throws {
        let mapper = createMapper()
        
        mapper.cpuWrite(0x00, at: 0x0000)
        mapper.cpuWrite(0x00, at: 0x8000)
        
        #expect(mapper.shift == 0b1000_0000)
    }

    @Test func consecutive_writes_get_bypassed_by_reset() async throws {
        let mapper = createMapper()
        
        mapper.cpuWrite(0x00, at: 0x8000)
        mapper.cpuWrite(0x80, at: 0x8000)
        
        #expect(mapper.shift == 0b1000_0000)
    }

    @Test func reset_when_load_register_has_bit7_set() async throws {
        let mapper = createMapper()
        mapper.control = 0x10
        
        mapper.cpuWrite(0x00, at: 0x8000)
        _ = mapper.cpuRead(at: 0x8000)
        mapper.cpuWrite(0x80, at: 0x8000)
        
        #expect(mapper.shift == 0b1000_0000)
        #expect(mapper.control == 0x1C) // control = control | 0x0C
    }

    @Test func write_to_control_register() async throws {
        let mapper = createMapper()
        mapper.control = 0xFF
        
        mapper.cpuWrite(0x00, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x00, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x00, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x00, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x00, at: 0x8000)

        #expect(mapper.control == 0x00)
        #expect(mapper.chrbank0 == 0)
        #expect(mapper.chrbank1 == 0)
        #expect(mapper.pgrbank == 0)
        #expect(mapper.shift == 0b1000_0000)
    }
    
    @Test func write_to_chr_bank0_register() async throws {
        let mapper = createMapper()
        
        mapper.cpuWrite(0x01, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xA000)

        #expect(mapper.control == 0x0C)
        #expect(mapper.chrbank0 == 0b0001_1111)
        #expect(mapper.chrbank1 == 0)
        #expect(mapper.pgrbank == 0)
        #expect(mapper.shift == 0b1000_0000)
    }
    
    @Test func write_to_chr_bank1_register() async throws {
        let mapper = createMapper()
        
        mapper.cpuWrite(0x01, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x00, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x00, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xC000)

        #expect(mapper.control == 0x0C)
        #expect(mapper.chrbank0 == 0)
        #expect(mapper.chrbank1 == 0b0001_0101)
        #expect(mapper.pgrbank == 0)
        #expect(mapper.shift == 0b1000_0000)
    }
    
    @Test func write_to_pgr_bank_register() async throws {
        let mapper = createMapper()
        
        mapper.cpuWrite(0x00, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x00, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xFFFF)
        _ = mapper.cpuRead(at: 0xFFFF)
        mapper.cpuWrite(0x01, at: 0xE000)

        #expect(mapper.control == 0x0C)
        #expect(mapper.chrbank0 == 0)
        #expect(mapper.chrbank1 == 0)
        #expect(mapper.pgrbank == 0b0000_1100)
        #expect(mapper.shift == 0b1000_0000)
        #expect(mapper.sramEnabled == true)
    }
}

