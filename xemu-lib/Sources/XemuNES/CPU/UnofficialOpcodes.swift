import XemuFoundation

extension MOS6502 {
    func alr(_ value: u8) {
        and(value)
        registers.a = lsr(registers.a)
    }
    
    func anc(_ value: u8) {
        and(value)
        registers.p.carry = Bool(registers.a & 0b1000_0000)
    }
    
    func arr(_ value: u8) {
        and(value)
        let result = registers.a
        registers.a = ror(result)
        registers.p.carry = Bool(registers.a & 0b0100_0000)
        registers.p.overflow = Bool(((registers.a & 0b0100_0000) >> 6) ^ ((registers.a & 0b0010_0000) >> 5))
    }
    
    func axs(_ value: u8) {
        let result = registers.a & registers.x
        registers.p.carry = result >= value
        registers.x = result &- value
        registers.p.setNZ(registers.x)
    }
    
    func dcp(_ value: u8) -> u8 {
        let result = dec(value)
        cmp(result)
        
        return result
    }
    
    func isc(_ value: u8) -> u8 {
        let result = inc(value)
        sbc(result)
        
        return result
    }

    func las(_ value: u8) {
        let result = registers.s & value
        registers.a = result
        registers.x = result
        registers.s = result
    }
    
    func lax(_ value: u8) {
        lda(value)
        registers.x = value
    }
    
    func rla(_ value: u8) -> u8 {
        let result = rol(value)
        and(result)
        return result
    }

    func rra(_ value: u8) -> u8 {
        let result = ror(value)
        adc(result)
        return result
    }

    func sax() -> u8 {
        registers.a & registers.x
    }
    
    func SyaSxaAxa(_ address: u16, _ index: u8, _ value: u8) {
        let crossedPage = isCrossingPage(a: address, b: index)
        
        let cycle = cycles
        read8(at: address &+ u16(index) &- (crossedPage ? 0x100 : 0))
        
        let dma = cycles - cycle > 1
        
        let operand = address + u16(index)
        
        var hi = u8(operand >> 8)
        let lo = u8(operand & 0xff)
        
        if crossedPage {
            hi &= value
        }
        
        let value = dma ? value : value & (u8(address >> 8) &+ 1)
        
        write8(value, at: u16(hi: hi, lo: lo))
    }
    
    func shaa() {
        SyaSxaAxa(read16(), registers.y, registers.x & registers.a)
    }
    
    func shaz() {
        let pageZeroAddress = read8()
        
        var address: u16
        
        if pageZeroAddress == 0xff {
            let lo = read8(at: 0xff)
            let hi = read8(at: 0x00)
            address = u16(hi: hi, lo: lo)
        } else {
            address = read16(at: u16(pageZeroAddress))
        }
        
        SyaSxaAxa(address, registers.y, registers.x & registers.a)
    }

    func shx() {
        SyaSxaAxa(read16(), registers.y, registers.x)
    }
    
    func shy() {
        SyaSxaAxa(read16(), registers.x, registers.y)
    }

    func tas() {
        shaa()
        registers.s = registers.x & registers.a
    }

    func slo(_ value: u8) -> u8 {
        let result = asl(value)
        ora(result)
        
        return result
    }
    
    func sre(_ value: u8) -> u8 {
        let result = lsr(value)
        eor(result)
        
        return result
    }

    /// Highly unstable, do not use
    /// A base value in A is determined based on the contents of A and a constant,
    /// which may be typically $00, $ff, $ee, etc. The value of this constant
    /// depends on temerature, the chip series, and maybe other factors, as well.
    /// In order to eliminate these uncertaincies from the equation,
    /// use either 0 as the operand or a value of $FF in the accumulator
    func xaa(_ value: u8) {
        let magic: u8 = 0x00
        registers.a = (registers.a | magic) & registers.x & value
        registers.p.setNZ(registers.a)
    }
}
