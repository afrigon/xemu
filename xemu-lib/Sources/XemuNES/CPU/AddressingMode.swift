import XemuFoundation

typealias ReadOpcodeHandler = (u8) -> Void
typealias ModifyOpcodeHandler = (u8) -> u8
typealias WriteOpcodeHandler = () -> u8

extension MOS6502 {
    
    // Called by Immediate STA. Does nothing and skip the operand byte.
    @inline(__always) func ignoreImmediateWrite(_ fn: WriteOpcodeHandler) {
        registers.pc &+= 1
        state.tick = 0
    }
    
    // MARK: Implied Addressing Mode
    
    @inline(__always) func handleImplied(_ fn: @escaping () -> Void) {
        fn()
        state.tick = 0
    }
    
    // MARK: Accumulator Addressing Mode
    
    @inline(__always) func handleAccumulatorModify(_ fn: ModifyOpcodeHandler) {
        registers.a = fn(registers.a)
        state.tick = 0
    }
    
    // MARK: Immediate Addressing Mode
    
    @inline(__always) func handleImmediateRead(_ fn: ReadOpcodeHandler) {
        fn(read8())
        state.tick = 0
    }

    // MARK: Absolute Addressing Mode
    
    func handleAbsoluteRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
            case 4:
                fn(bus.read(at: state.data))
                state.tick = 0
            default:
                break
        }
    }
    
    func handleAbsoluteModify(_ fn: ModifyOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
                state.temp = state.lo
            case 4:
                state.temp = bus.read(at: state.data)
            case 5:
                bus.write(state.temp, at: state.data)
                state.temp = fn(state.temp)
            case 6:
                bus.write(state.temp, at: state.data)
                state.tick = 0
            default:
                break
        }
    }
    
    func handleAbsoluteWrite(_ fn: WriteOpcodeHandler){
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
            case 4:
                bus.write(fn(), at: state.data)
                state.tick = 0
            default:
                break
        }
    }
    
    // MARK: Absolute Indexed X Addressing Mode
    
    func handleAbsoluteIndexedXRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
                state.temp = state.hi
                state.data &+= u16(registers.x)
            case 4:
                // check if the hi byte of the effective address was changed by the index
                if state.temp == state.hi {
                    fn(bus.read(at: state.data))
                    state.tick = 0
                } else {
                    bus.read(at: u16(state.temp) << 8 | u16(state.lo))
                }
            case 5:
                fn(bus.read(at: state.data))
                state.tick = 0
            default:
                break
        }
    }
    
    func handleAbsoluteIndexedXModify(_ fn: ModifyOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
                state.temp = state.hi
                state.data &+= u16(registers.x)
            case 4:
                bus.read(at: u16(state.temp) << 8 | u16(state.lo))
            case 5:
                state.temp = bus.read(at: state.data)
            case 6:
                bus.write(state.temp, at: state.data)
                state.temp = fn(state.temp)
            case 7:
                bus.write(state.temp, at: state.data)
                state.tick = 0
            default:
                break
        }
    }
    
    func handleAbsoluteIndexedXWrite(_ fn: WriteOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
                state.temp = state.hi
                state.data &+= u16(registers.x)
            case 4:
                // check if the hi byte of the effective address was changed by the index
                bus.read(at: u16(state.temp) << 8 | u16(state.lo))
            case 5:
                bus.write(fn(), at: state.data)
                state.tick = 0
            default:
                break
        }
    }
    
    // MARK: Absolute Indexed Y Addressing Mode
    
    func handleAbsoluteIndexedYRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
                state.temp = state.hi
                state.data &+= u16(registers.y)
            case 4:
                // check if the high byte of the effective address was changed by the index
                if state.temp == state.hi {
                    fn(bus.read(at: state.data))
                    state.tick = 0
                } else {
                    bus.read(at: u16(state.temp) << 8 | u16(state.lo))
                }
            case 5:
                fn(bus.read(at: state.data))
                state.tick = 0
            default:
                break
        }
    }
    
    func handleAbsoluteIndexedYModify(_ fn: ModifyOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
                state.temp = state.hi
                state.data &+= u16(registers.y)
            case 4:
                bus.read(at: u16(state.temp) << 8 | u16(state.lo))
            case 5:
                state.temp = bus.read(at: state.data)
            case 6:
                bus.write(state.temp, at: state.data)
                state.temp = fn(state.temp)
            case 7:
                bus.write(state.temp, at: state.data)
                state.tick = 0
            default:
                break
        }
    }
    
    func handleAbsoluteIndexedYWrite(_ fn: WriteOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.hi = read8()
                state.temp = state.hi
                state.data &+= u16(registers.y)
            case 4:
                // check if the hi byte of the effective address was changed by the index
                bus.read(at: u16(state.temp) << 8 | u16(state.lo))
            case 5:
                bus.write(fn(), at: state.data)
                state.tick = 0
            default:
                break
        }
    }

    // MARK: Zero Page Addressing Mode
    
    func handleZeroPageRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                fn(bus.readZeroPage(at: state.lo))
                state.tick = 0
            default:
                break
        }
    }
    
    func handleZeroPageModify(_ fn: ModifyOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                state.temp = bus.readZeroPage(at: state.lo)
            case 4:
                bus.writeZeroPage(state.temp, at: state.lo)
                state.temp = fn(state.temp)
            case 5:
                bus.writeZeroPage(state.temp, at: state.lo)
                state.tick = 0
            default:
                break
        }
    }
    
    func handleZeroPageWrite(_ fn: WriteOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.writeZeroPage(fn(), at: state.lo)
                state.tick = 0
            default:
                break
        }
    }
    
    // MARK: Zero Paged Indexed X Addressing Mode
    
    func handleZeroPageIndexedXRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.readZeroPage(at: state.lo)
                state.lo &+= registers.x
            case 4:
                fn(bus.readZeroPage(at: state.lo))
                state.tick = 0
            default:
                break
        }
    }
    
    func handleZeroPageIndexedXModify(_ fn: ModifyOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.readZeroPage(at: state.lo)
                state.lo &+= registers.x
            case 4:
                state.temp = bus.readZeroPage(at: state.lo)
            case 5:
                bus.writeZeroPage(state.temp, at: state.lo)
                state.temp = fn(state.temp)
            case 6:
                bus.writeZeroPage(state.temp, at: state.lo)
                state.tick = 0
            default:
                break
        }
    }
    
    func handleZeroPageIndexedXWrite(_ fn: WriteOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.readZeroPage(at: state.lo)
                state.lo &+= registers.x
            case 4:
                bus.writeZeroPage(fn(), at: state.lo)
                state.tick = 0
            default:
                break
        }
    }

    // MARK: Zero Paged Indexed Y Addressing Mode
    
    func handleZeroPageIndexedYRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.readZeroPage(at: state.lo)
                state.lo &+= registers.y
            case 4:
                fn(bus.readZeroPage(at: state.lo))
                state.tick = 0
            default:
                break
        }
    }
    
    func handleZeroPageIndexedYModify(_ fn: ModifyOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.readZeroPage(at: state.lo)
                state.lo &+= registers.y
            case 4:
                state.temp = bus.readZeroPage(at: state.lo)
            case 5:
                bus.writeZeroPage(state.temp, at: state.lo)
                state.temp = fn(state.temp)
            case 6:
                bus.writeZeroPage(state.temp, at: state.lo)
                state.tick = 0
            default:
                break
        }
    }
    
    func handleZeroPageIndexedYWrite(_ fn: WriteOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.readZeroPage(at: state.lo)
                state.lo &+= registers.y
            case 4:
                bus.writeZeroPage(fn(), at: state.lo)
                state.tick = 0
            default:
                break
        }
    }
    
    // MARK: Indexed Indirect (X) Addressing Mode
    
    func handleIndexedIndirectXRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.read(at: u16(state.lo))
                state.lo &+= registers.x
            case 4:
                state.temp = bus.read(at: u16(state.lo))
            case 5:
                state.hi = bus.read(at: u16(state.lo &+ 1))
                state.lo = state.temp
            case 6:
                fn(bus.read(at: state.data))
                state.tick = 0
            default:
                break
        }
    }
    
    func handleIndexedIndirectXModify(_ fn: ModifyOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.read(at: u16(state.lo))
                state.lo &+= registers.x
            case 4:
                state.temp = bus.read(at: u16(state.lo))
            case 5:
                state.hi = bus.read(at: u16(state.lo &+ 1))
                state.lo = state.temp
            case 6:
                state.temp = bus.read(at: state.data)
            case 7:
                bus.write(state.temp, at: state.data)
                state.temp = fn(state.temp)
            case 8:
                bus.write(state.temp, at: state.data)
                state.tick = 0
            default:
                break
        }
    }
    
    func handleIndexedIndirectXWrite(_ fn: WriteOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                bus.read(at: u16(state.lo))
                state.lo &+= registers.x
            case 4:
                state.temp = bus.read(at: u16(state.lo))
            case 5:
                state.hi = bus.read(at: u16(state.lo &+ 1))
                state.lo = state.temp
            case 6:
                bus.write(fn(), at: state.data)
                state.tick = 0
            default:
                break
        }
    }

    // MARK: Indirect Indexed (Y) Addressing Mode
    
    func handleIndirectIndexedYRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.temp = read8()
            case 3:
                state.lo = bus.read(at: u16(state.temp))
            case 4:
                state.hi = bus.read(at: u16(state.temp &+ 1))
                state.temp = state.hi
                state.data &+= u16(registers.y)
            case 5:
                if state.hi == state.temp {
                    fn(bus.read(at: state.data))
                    state.tick = 0
                } else {
                    bus.read(at: u16(state.temp) << 8 | u16(state.lo))
                }
            case 6:
                fn(bus.read(at: state.data))
                state.tick = 0
            default:
                break
        }
    }
    
    func handleIndirectIndexedYModify(_ fn: ModifyOpcodeHandler) {
        switch state.tick {
            case 2:
                state.temp = read8()
            case 3:
                state.lo = bus.read(at: u16(state.temp))
            case 4:
                state.hi = bus.read(at: u16(state.temp &+ 1))
                state.temp = state.hi
                state.data &+= u16(registers.y)
            case 5:
                bus.read(at: u16(state.temp) << 8 | u16(state.lo))
            case 6:
                state.temp = bus.read(at: state.data)
            case 7:
                bus.write(state.temp, at: state.data)
                state.temp = fn(state.temp)
            case 8:
                bus.write(state.temp, at: state.data)
                state.tick = 0
            default:
                break
        }
    }
    
    func handleIndirectIndexedYWrite(_ fn: WriteOpcodeHandler) {
        switch state.tick {
            case 2:
                state.temp = read8()
            case 3:
                state.lo = bus.read(at: u16(state.temp))
            case 4:
                state.hi = bus.read(at: u16(state.temp &+ 1))
                state.temp = state.hi
                state.data &+= u16(registers.y)
            case 5:
                bus.read(at: u16(state.temp) << 8 | u16(state.lo))
            case 6:
                bus.write(fn(), at: state.data)
                state.tick = 0
            default:
                break
        }
    }
}

