import XemuFoundation

typealias ReadOpcodeHandler = (u8) -> Void
typealias ModifyOpcodeHandler = (u8) -> u8
typealias WriteOpcodeHandler = () -> u8

class AddressingModeHandler {
    var read: (ReadOpcodeHandler) -> Void
    var modify: (ModifyOpcodeHandler) -> Void
    var write: (WriteOpcodeHandler) -> Void
    
    init(
        read: @escaping (ReadOpcodeHandler) -> Void,
        modify: @escaping (ModifyOpcodeHandler) -> Void,
        write: @escaping (WriteOpcodeHandler) -> Void
    ) {
        self.read = read
        self.modify = modify
        self.write = write
    }
}

extension MOS6502 {
    
    // Called by Immediate STA. Does nothing and skip the operand byte.
    func ignoreImmediateWrite(_ fn: WriteOpcodeHandler) {
        registers.pc &+= 1
        state.tick = 0
    }

    // MARK: Unimplemented Addressing Mode
    
    func handleUnimplementedRead(_ fn: ReadOpcodeHandler) {
        fatalError("unimplemented read \(state.opcode.hex(toLength: 2))")
    }
    
    func handleUnimplementedModify(_ fn: ModifyOpcodeHandler) {
        fatalError("unimplemented modify \(state.opcode.hex(toLength: 2))")
    }

    func handleUnimplementedWrite(_ fn: WriteOpcodeHandler) {
        fatalError("unimplemented write \(state.opcode.hex(toLength: 2))")
    }
    
    // MARK: Implied Addressing Mode
    
    func handleImplied(_ fn: @escaping () -> Void) {
        fn()
        state.tick = 0
    }
    
    // MARK: Accumulator Addressing Mode
    
    func handleAccumulatorModify(_ fn: ModifyOpcodeHandler) {
        registers.a = fn(registers.a)
        state.tick = 0
    }
    
    // MARK: Immediate Addressing Mode
    
    func handleImmediateRead(_ fn: ReadOpcodeHandler) {
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
                let address = state.data
                fn(bus.read(at: address))
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
    }
    
    func handleAbsoluteIndexedXModify(_ fn: ModifyOpcodeHandler) {
    }
    
    func handleAbsoluteIndexedXWrite(_ fn: WriteOpcodeHandler) {
    }
    
    // MARK: Absolute Indexed Y Addressing Mode
    
    func handleAbsoluteIndexedYRead(_ fn: ReadOpcodeHandler) {
    }
    
    func handleAbsoluteIndexedYModify(_ fn: ModifyOpcodeHandler) {
    }
    
    func handleAbsoluteIndexedYWrite(_ fn: WriteOpcodeHandler) {
    }

    // MARK: Zero Page Addressing Mode
    
    func handleZeroPageRead(_ fn: ReadOpcodeHandler) {
        switch state.tick {
            case 2:
                state.lo = read8()
            case 3:
                fn(bus.read(at: u16(state.lo)))
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
                state.temp = bus.read(at: u16(state.lo))
            case 4:
                bus.write(state.temp, at: u16(state.lo))
                state.temp = fn(state.temp)
            case 5:
                bus.write(state.temp, at: u16(state.lo))
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
                bus.write(fn(), at: u16(state.lo))
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
                _ = bus.read(at: u16(state.lo))
                state.lo &+= registers.x
            case 4:
                fn(bus.read(at: u16(state.lo)))
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
                _ = bus.read(at: u16(state.lo))
                state.lo &+= registers.x
            case 4:
                state.temp = bus.read(at: u16(state.lo))
            case 5:
                bus.write(state.temp, at: u16(state.lo))
                state.temp = fn(state.temp)
            case 6:
                bus.write(state.temp, at: u16(state.lo))
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
                _ = bus.read(at: u16(state.lo))
                state.lo &+= registers.x
            case 4:
                bus.write(fn(), at: u16(state.lo))
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
                _ = bus.read(at: u16(state.lo))
                state.lo &+= registers.y
            case 4:
                fn(bus.read(at: u16(state.lo)))
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
                _ = bus.read(at: u16(state.lo))
                state.lo &+= registers.y
            case 4:
                state.temp = bus.read(at: u16(state.lo))
            case 5:
                bus.write(state.temp, at: u16(state.lo))
                state.temp = fn(state.temp)
            case 6:
                bus.write(state.temp, at: u16(state.lo))
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
                _ = bus.read(at: u16(state.lo))
                state.lo &+= registers.y
            case 4:
                bus.write(fn(), at: u16(state.lo))
                state.tick = 0
            default:
                break
        }
    }
    
    // MARK: Indexed Indirect (X) Addressing Mode
    
    func handleIndexedIndirectRead(_ fn: ReadOpcodeHandler) {
    }
    
    func handleIndexedIndirectModify(_ fn: ModifyOpcodeHandler) {
    }
    
    func handleIndexedIndirectWrite(_ fn: WriteOpcodeHandler) {
    }

    // MARK: Indirect Indexed (Y) Addressing Mode
    
    func handleIndirectIndexedRead(_ fn: ReadOpcodeHandler) {
    }
    
    func handleIndirectIndexedModify(_ fn: ModifyOpcodeHandler) {
    }
    
    func handleIndirectIndexedWrite(_ fn: WriteOpcodeHandler) {
    }
}

