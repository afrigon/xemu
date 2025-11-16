import XemuFoundation

extension MOS6502 {
    
    /// No Operation
    /// The NOP instruction causes no changes to the processor other than the
    /// normal incrementing of the program counter to the next instruction
    @inline(__always) func nop() {
        
    }
    
    /// No Operation
    /// The NOP instruction causes no changes to the processor other than the
    /// normal incrementing of the program counter to the next instruction
    @inline(__always) func nopRead(_ value: u8) {
        
    }

    /// Jump
    /// Sets the program counter to the address specified by the operand
    func jmpAbsolute() {
        registers.pc = read16()
    }
    
    /// Jump
    /// Sets the program counter to the address specified by the operand
    func jmpIndirect() {
        let ptr = read16()
        
        var address: u16
        
        if (ptr & 0xff) == 0xff {
            let lo = read8(at: ptr)
            let hi = read8(at: ptr - 0xff)
            address = u16(hi: hi, lo: lo)
        } else {
            address = read16(at: ptr)
        }
        
        registers.pc = address
    }
    
    /// Jump to Subroutine
    /// The JSR instruction pushes the address (minus one) of the return point
    /// on to the stack and then sets the program counter to the target memory address
    func jsr() {
        let lo = read8()
        peek8()
        push16(registers.pc)
        let hi = read8()
        
        let address = u16(hi: hi, lo: lo)
        registers.pc = address
    }
    
    /// Return from Subroutine
    /// The RTS instruction is used at the end of a subroutine to return to the
    /// calling routine. It pulls the program counter (minus one) from the stack
    func rts() {
        peek8()
        let address = pop16()
        peek8()
        registers.pc = address + 1
    }

    /// Push Accumulator
    /// Pushes a copy of the accumulator on to the stack
    func pha() {
        peek8()
        push8(registers.a)
    }
    
    /// Push Processor Status
    /// Pushes a copy of the status flags on to the stack
    func php() {
        peek8()
        push8(registers.p.value(b: true))
    }
    
    /// Pull Accumulator
    /// Pulls an 8 bit value from the stack and into the accumulator.
    /// The zero and negative flags are set as appropriate
    func pla() {
        peek8()
        peek8()
        registers.a = pop8()
        registers.p.setNZ(registers.a)
    }
    
    /// Pull Processor Status
    /// Pulls an 8 bit value from the stack and into the processor flags.
    /// The flags will take on new states as determined by the value pulled
    func plp() {
        peek8()
        peek8()
        registers.p.set(pop8())
    }
    
    /// Clear Carry Flag
    /// Set the carry flag to zero
    func clc() {
        registers.p.carry = false
    }
    
    /// Clear Decimal Mode
    /// Sets the decimal mode flag to zero
    func cld() {
        registers.p.decimal = false
    }
    
    /// Clear Interrupt Disable
    /// Clears the interrupt disable flag allowing normal interrupt requests
    /// to be serviced
    func cli() {
        registers.p.interruptDisabled = false
    }
    
    /// Clear Overflow Flag
    /// Clear the overflow flag
    func clv() {
        registers.p.overflow = false
    }
    
    /// Set Carry Flag
    /// Set the carry flag to one
    func sec() {
        registers.p.carry = true
    }
    
    /// Set Decimal Flag
    /// Set the decimal mode flag to one
    func sed() {
        registers.p.decimal = true
    }
    
    /// Set Interrupt Disable
    /// Set the interrupt disable flag to one
    func sei() {
        registers.p.interruptDisabled = true
    }
    
    /// Logical Inclusive OR
    /// An inclusive OR is performed, bit by bit, on the accumulator contents
    /// using the contents of a byte of memory
    func ora(_ value: u8) {
        registers.a |= value
        registers.p.setNZ(registers.a)
    }
    
    /// Logical AND
    /// A logical AND is performed, bit by bit, on the accumulator contents
    /// using the contents of a byte of memory
    func and(_ value: u8) {
        registers.a &= value
        registers.p.setNZ(registers.a)
    }
    
    /// Exclusive OR
    /// An exclusive OR is performed, bit by bit, on the accumulator contents
    /// using the contents of a byte of memory
    func eor(_ value: u8) {
        registers.a ^= value
        registers.p.setNZ(registers.a)
    }
    
    /// Bit Test
    /// This instructions is used to test if one or more bits are set in a
    /// target memory location. The mask pattern in A is ANDed with the value
    /// in memory to set or clear the zero flag, but the result is not kept.
    /// Bits 7 and 6 of the value from memory are copied into the N and V flags
    func bit(_ value: u8) {
        registers.p.zero = !Bool(registers.a & value)
        registers.p.overflow = Bool(value & 0b0100_0000)
        registers.p.negative = Bool(value & 0b1000_0000)
    }
    
    /// Add with Carry
    /// This instruction adds the contents of a memory location to the
    /// accumulator together with the carry bit. If overflow occurs the carry
    /// bit is set, this enables multiple byte addition to be performed
    func adc(_ value: u8) {
        let result = u16(registers.a) &+ u16(value) &+ u16(registers.p.carry)
        
        // overflow happens when register and value have the same sign (bit 7), but result does not
        registers.p.overflow = Bool(~(registers.a ^ value) & (registers.a ^ u8(result & 0xFF)) & 0b1000_0000)
        registers.p.carry = result > 0xFF
        registers.a = u8(result & 0xFF)
        registers.p.setNZ(registers.a)
    }

    /// Subtract with Carry
    /// This instruction subtracts the contents of a memory location to the
    /// accumulator together with the not of the carry bit. If overflow occurs
    /// the carry bit is clear, this enables multiple byte subtraction to be performed
    func sbc(_ value: u8) {
        let result = u16(registers.a) &- u16(value) &- u16(!registers.p.carry)
        
        // overflow happens when register and value have different sign (bit 7), and result is the same sign as value
        registers.p.overflow = Bool((registers.a ^ value) & (registers.a ^ u8(result & 0xFF)) & 0b1000_0000)
        registers.p.carry = result <= 0xFF
        registers.a = u8(result & 0xFF)
        registers.p.setNZ(registers.a)
    }
    
    /// Increment Memory
    /// Adds one to the value held at a specified memory location setting the
    /// zero and negative flags as appropriate
    func inc(_ value: u8) -> u8 {
        let result = value &+ 1
        registers.p.setNZ(result)
        
        return result
    }
    
    /// Increment X Register
    /// Adds one to the X register setting the zero and negative flags as appropriate
    func inx() {
        registers.x &+= 1
        registers.p.setNZ(registers.x)
    }
    
    /// Increment Y Register
    /// Adds one to the Y register setting the zero and negative flags as appropriate
    func iny() {
        registers.y &+= 1
        registers.p.setNZ(registers.y)
    }
    
    /// Decrement Memory
    /// Subtracts one from the value held at a specified memory location setting
    /// the zero and negative flags as appropriate
    func dec(_ value: u8) -> u8 {
        let result = value &- 1
        registers.p.setNZ(result)
        
        return result
    }
    
    /// Decrement X Register
    /// Subtracts one from the X register setting the zero and negative flags as appropriate
    func dex() {
        registers.x &-= 1
        registers.p.setNZ(registers.x)
    }
    
    /// Decrement Y Register
    /// Subtracts one from the Y register setting the zero and negative flags as appropriate
    func dey() {
        registers.y &-= 1
        registers.p.setNZ(registers.y)
    }
    
    /// Arithmetic Shift Left
    /// This operation shifts all the bits of the accumulator or memory contents
    /// one bit left. Bit 0 is set to 0 and bit 7 is placed in the carry flag.
    /// The effect of this operation is to multiply the memory contents by 2
    /// (ignoring 2's complement considerations), setting the carry if the
    /// result will not fit in 8 bits
    func asl(_ value: u8) -> u8 {
        registers.p.carry = Bool(value & 0b1000_0000)
        
        let result = value << 1
        registers.p.setNZ(result)
        
        return result
    }
    
    /// Logical Shift Right
    /// Each of the bits in A or M is shift one place to the right. The bit that
    /// was in bit 0 is shifted into the carry flag. Bit 7 is set to zero
    func lsr(_ value: u8) -> u8 {
        registers.p.carry = Bool(value & 0b0000_0001)
        
        let result = value >> 1
        registers.p.zero = !Bool(result)
        registers.p.negative = false
        
        return result
    }
    
    /// Rotate Left
    /// Move each of the bits in either A or M one place to the left.
    /// Bit 0 is filled with the current value of the carry flag whilst the old
    /// bit 7 becomes the new carry flag value
    func rol(_ value: u8) -> u8 {
        let carry = u8(registers.p.carry)
        registers.p.carry = Bool(value & 0b1000_0000)
        
        let result = value << 1 | carry
        registers.p.setNZ(result)
        
        return result
    }
    
    /// Rotate Right
    /// Move each of the bits in either A or M one place to the right.
    /// Bit 7 is filled with the current value of the carry flag whilst the old
    /// bit 0 becomes the new carry flag value
    func ror(_ value: u8) -> u8 {
        let carry = u8(registers.p.carry)
        registers.p.carry = Bool(value & 0b0000_0001)
        
        let result = value >> 1 | carry << 7
        registers.p.setNZ(result)
        
        return result
    }
    
    /// Load Accumulator
    /// Loads a byte of memory into the accumulator setting the zero
    /// and negative flags as appropriate
    func lda(_ value: u8) {
        registers.a = value
        registers.p.setNZ(value)
    }
    
    /// Load X Register
    /// Loads a byte of memory into the X register setting the zero
    /// and negative flags as appropriate
    func ldx(_ value: u8) {
        registers.x = value
        registers.p.setNZ(value)
    }
    
    /// Load Y Register
    /// Loads a byte of memory into the Y register setting the zero
    /// and negative flags as appropriate
    func ldy(_ value: u8) {
        registers.y = value
        registers.p.setNZ(value)
    }

    /// Store Accumulator
    /// Stores the contents of the accumulator into memory
    func sta() -> u8 {
        registers.a
    }
    
    /// Store X Register
    /// Stores the contents of the X register into memory
    func stx() -> u8 {
        registers.x
    }
    
    /// Store Y Register
    /// Stores the contents of the Y register into memory
    func sty() -> u8 {
        registers.y
    }
    
    /// Transfer Accumulator to X
    /// Copies the current contents of the accumulator into the X register
    /// and sets the zero and negative flags as appropriate
    func tax() {
        registers.x = registers.a
        registers.p.setNZ(registers.x)
    }
    
    /// Transfer Accumulator to Y
    /// Copies the current contents of the accumulator into the Y register
    /// and sets the zero and negative flags as appropriate
    func tay() {
        registers.y = registers.a
        registers.p.setNZ(registers.y)
    }
    
    /// Transfer Stack Pointer to X
    /// Copies the current contents of the stack register into the X register
    /// and sets the zero and negative flags as appropriate
    func tsx() {
        registers.x = registers.s
        registers.p.setNZ(registers.x)
    }
    
    /// Transfer X to Accumulator
    /// Copies the current contents of the X register into the accumulator
    /// and sets the zero and negative flags as appropriate
    func txa() {
        registers.a = registers.x
        registers.p.setNZ(registers.a)
    }
    
    /// Transfer X to Stack Pointer
    /// Copies the current contents of the X register into the stack register
    func txs() {
        registers.s = registers.x
    }
    
    /// Transfer Y to Accumulator
    /// Copies the current contents of the Y register into the accumulator
    /// and sets the zero and negative flags as appropriate
    func tya() {
        registers.a = registers.y
        registers.p.setNZ(registers.a)
    }

    /// Compare
    /// This instruction compares the contents of the accumulator with another
    /// memory held value and sets the zero and carry flags as appropriate
    func cmp(_ value: u8) {
        registers.p.carry = registers.a >= value
        registers.p.setNZ(registers.a &- value)
    }
    
    /// Compare X Register
    /// This instruction compares the contents of the X register with another
    /// memory held value and sets the zero and carry flags as appropriate
    func cpx(_ value: u8) {
        registers.p.carry = registers.x >= value
        registers.p.setNZ(registers.x &- value)
    }
    
    /// Compare Y Register
    /// This instruction compares the contents of the Y register with another
    /// memory held value and sets the zero and carry flags as appropriate
    func cpy(_ value: u8) {
        registers.p.carry = registers.y >= value
        registers.p.setNZ(registers.y &- value)
    }
    
    /// Branch (BCC, BCS, BEQ, BMI, BNE, BPL, BVC, BVS)
    /// if the condition is met then add the relative displacement to the
    /// program counter to cause a branch to a new location
    func branch() {
        let lo = read8()
        
        let flagValue = Bool(state.opcode & 0b0010_0000)
        let flagIndex = (state.opcode & 0b1100_0000) >> 6
        
        let shouldBranch = switch flagIndex {
            case 0b00: flagValue == registers.p.negative
            case 0b01: flagValue == registers.p.overflow
            case 0b10: flagValue == registers.p.carry
            case 0b11: flagValue == registers.p.zero
            default: false
        }
        
        if shouldBranch {
            if state.irqPending && !state.irqOldPending {
                state.irqPending = false
            }
            
            peek8()
            let crossedPage = isCrossingPage(a: registers.pc, b: i8(bitPattern: lo))
            let address = i32(registers.pc) &+ i32(i8(bitPattern: lo))
            registers.pc = (registers.pc & 0xFF00) | u16(address & 0xFF)
            
            if crossedPage {
                peek8()
                registers.pc = u16(
                    hi: u8(truncatingIfNeeded: address >> 8),
                    lo: u8(registers.pc & 0xFF)
                )
            }
        }
    }
}
