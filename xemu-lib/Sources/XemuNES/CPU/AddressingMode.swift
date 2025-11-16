import XemuFoundation

typealias ReadOpcodeHandler = (u8) -> Void
typealias ModifyOpcodeHandler = (u8) -> u8
typealias WriteOpcodeHandler = () -> u8

extension MOS6502 {
    
    // MARK: Implied Addressing Mode
    
    @inline(__always) func handleImplied(_ fn: @escaping () -> Void) {
        peek8()
        fn()
    }
    
    // MARK: Accumulator Addressing Mode
    
    @inline(__always) func handleAccumulatorModify(_ fn: ModifyOpcodeHandler) {
        peek8()
        registers.a = fn(registers.a)
    }
    
    // MARK: Immediate Addressing Mode
    
    @inline(__always) func handleImmediateRead(_ fn: ReadOpcodeHandler) {
        fn(read8())
    }

    // MARK: Absolute Addressing Mode
    
    func handleAbsoluteRead(_ fn: ReadOpcodeHandler) {
        let address = read16()
        let operand = read8(at: address)
        fn(operand)
    }
    
    func handleAbsoluteModify(_ fn: ModifyOpcodeHandler) {
        let address = read16()
        let data = read8(at: address)
        write8(data, at: address)
        write8(fn(data), at: address)
    }
    
    func handleAbsoluteWrite(_ fn: WriteOpcodeHandler){
        let address = read16()
        write8(fn(), at: address)
    }
    
    // MARK: Absolute Indexed X Addressing Mode
    
    func handleAbsoluteIndexedXRead(_ fn: ReadOpcodeHandler) {
        var address = read16()
        let crossedPage = isCrossingPage(a: address, b: registers.x)
        
        address &+= u16(registers.x)
        
        if crossedPage {
            read8(at: address &- 0x100)
        }
        
        fn(read8(at: address))
    }
    
    func handleAbsoluteIndexedXModify(_ fn: ModifyOpcodeHandler) {
        var address = read16()
        
        let crossedPage = isCrossingPage(a: address, b: registers.x)
        address &+= u16(registers.x)
        
        read8(at: address &- (crossedPage ? 0x100 : 0))
        let operand = read8(at: address)
        write8(operand, at: address)
        write8(fn(operand), at: address)
    }
    
    func handleAbsoluteIndexedXWrite(_ fn: WriteOpcodeHandler) {
        var address = read16()
        
        let crossedPage = isCrossingPage(a: address, b: registers.x)
        address &+= u16(registers.x)
        
        read8(at: address &- (crossedPage ? 0x100 : 0))
        write8(fn(), at: address)
    }
    
    // MARK: Absolute Indexed Y Addressing Mode
    
    func handleAbsoluteIndexedYRead(_ fn: ReadOpcodeHandler) {
        var address = read16()
        let crossedPage = isCrossingPage(a: address, b: registers.y)
        
        address &+= u16(registers.y)
        
        if crossedPage {
            read8(at: address &- 0x100)
        }
        
        fn(read8(at: address))
    }
    
    func handleAbsoluteIndexedYModify(_ fn: ModifyOpcodeHandler) {
        var address = read16()
        
        let crossedPage = isCrossingPage(a: address, b: registers.y)
        address &+= u16(registers.y)
        
        read8(at: address &- (crossedPage ? 0x100 : 0))
        
        let operand = read8(at: address)
        write8(operand, at: address)
        write8(fn(operand), at: address)
    }
    
    func handleAbsoluteIndexedYWrite(_ fn: WriteOpcodeHandler) {
        var address = read16()
        
        let crossedPage = isCrossingPage(a: address, b: registers.y)
        address &+= u16(registers.y)
        
        read8(at: address &- (crossedPage ? 0x100 : 0))
        write8(fn(), at: address)
    }

    // MARK: Zero Page Addressing Mode
    
    func handleZeroPageRead(_ fn: ReadOpcodeHandler) {
        let address = u16(read8())
        fn(read8(at: address))
    }
    
    func handleZeroPageModify(_ fn: ModifyOpcodeHandler) {
        let address = u16(read8())
        let data = read8(at: address)
        write8(data, at: address)
        write8(fn(data), at: address)
    }
    
    func handleZeroPageWrite(_ fn: WriteOpcodeHandler) {
        let address = u16(read8())
        write8(fn(), at: address)
    }
    
    // MARK: Zero Paged Indexed X Addressing Mode
    
    func handleZeroPageIndexedXRead(_ fn: ReadOpcodeHandler) {
        let address = read8()
        read8(at: u16(address))
        fn(read8(at: u16(address &+ registers.x)))
    }
    
    func handleZeroPageIndexedXModify(_ fn: ModifyOpcodeHandler) {
        let address = read8()
        read8(at: u16(address))
        let offsetAddress = u16(address &+ registers.x)
        let data = read8(at: offsetAddress)
        write8(data, at: offsetAddress)
        write8(fn(data), at: offsetAddress)
    }
    
    func handleZeroPageIndexedXWrite(_ fn: WriteOpcodeHandler) {
        let address = read8()
        read8(at: u16(address))
        write8(fn(), at: u16(address &+ registers.x))
    }

    // MARK: Zero Paged Indexed Y Addressing Mode
    
    func handleZeroPageIndexedYRead(_ fn: ReadOpcodeHandler) {
        let address = read8()
        read8(at: u16(address))
        fn(read8(at: u16(address &+ registers.y)))
    }
    
    func handleZeroPageIndexedYModify(_ fn: ModifyOpcodeHandler) {
        let address = read8()
        read8(at: u16(address))
        let offsetAddress = u16(address &+ registers.y)
        let data = read8(at: offsetAddress)
        write8(data, at: offsetAddress)
        write8(fn(data), at: offsetAddress)
    }
    
    func handleZeroPageIndexedYWrite(_ fn: WriteOpcodeHandler) {
        let address = read8()
        read8(at: u16(address))
        write8(fn(), at: u16(address &+ registers.y))
    }
    
    // MARK: Indexed Indirect (X) Addressing Mode
    
    func handleIndexedIndirectXRead(_ fn: ReadOpcodeHandler) {
        var pageZeroAddress = read8()
        read8(at: u16(pageZeroAddress))
        pageZeroAddress &+= registers.x
        
        let lo = read8(at: u16(pageZeroAddress))
        let hi = read8(at: u16(pageZeroAddress &+ 1))
        
        let operand = read8(at: u16(hi: hi, lo: lo))
        fn(operand)
    }
    
    func handleIndexedIndirectXModify(_ fn: ModifyOpcodeHandler) {
        var pageZeroAddress = read8()
        read8(at: u16(pageZeroAddress))
        pageZeroAddress &+= registers.x
        
        let lo = read8(at: u16(pageZeroAddress))
        let hi = read8(at: u16(pageZeroAddress &+ 1))
        
        let address = u16(hi: hi, lo: lo)
        let operand = read8(at: address)
        write8(operand, at: address)
        write8(fn(operand), at: address)
    }
    
    func handleIndexedIndirectXWrite(_ fn: WriteOpcodeHandler) {
        var pageZeroAddress = read8()
        read8(at: u16(pageZeroAddress))
        pageZeroAddress &+= registers.x
        
        let lo = read8(at: u16(pageZeroAddress))
        let hi = read8(at: u16(pageZeroAddress &+ 1))
        
        write8(fn(), at: u16(hi: hi, lo: lo))
    }

    // MARK: Indirect Indexed (Y) Addressing Mode
    
    func handleIndirectIndexedYRead(_ fn: ReadOpcodeHandler) {
        let pageZeroAddress = read8()
        var address: u16
        
        if pageZeroAddress == 0xff {
            let lo = read8(at: 0xff)
            let hi = read8(at: 0x00)
            address = u16(hi: hi, lo: lo)
        } else {
            address = read16(at: u16(pageZeroAddress))
        }

        let crossedPage = isCrossingPage(a: address, b: registers.y)
        address &+= u16(registers.y)
        
        if crossedPage {
            read8(at: address &- 0x100)
        }
        
        fn(read8(at: address))
    }
    
    func handleIndirectIndexedYModify(_ fn: ModifyOpcodeHandler) {
        let pageZeroAddress = read8()
        var address: u16
        
        if pageZeroAddress == 0xff {
            let lo = read8(at: 0xff)
            let hi = read8(at: 0x00)
            address = u16(hi: hi, lo: lo)
        } else {
            address = read16(at: u16(pageZeroAddress))
        }

        let crossedPage = isCrossingPage(a: address, b: registers.y)
        address &+= u16(registers.y)
        read8(at: address &- (crossedPage ? 0x100 : 0))
        
        let operand = read8(at: address)
        write8(operand, at: address)
        write8(fn(operand), at: address)
    }
    
    func handleIndirectIndexedYWrite(_ fn: WriteOpcodeHandler) {
        let pageZeroAddress = read8()
        var address: u16
        
        if pageZeroAddress == 0xff {
            let lo = read8(at: 0xff)
            let hi = read8(at: 0x00)
            address = u16(hi: hi, lo: lo)
        } else {
            address = read16(at: u16(pageZeroAddress))
        }

        let crossedPage = isCrossingPage(a: address, b: registers.y)
        address &+= u16(registers.y)
        
        read8(at: address &- (crossedPage ? 0x100 : 0))
        
        write8(fn(), at: address)
    }
}

