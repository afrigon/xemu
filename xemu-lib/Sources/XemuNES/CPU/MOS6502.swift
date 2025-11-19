import XemuDebugger
import XemuFoundation
import XemuCore

public class MOS6502: Codable {
    var registers = Registers()
    var state = CpuState()
    
    var cycles: u64 = 0
    var clock = 0
    let ppuOffset = 1
    
    weak var bus: Bus!
    
    private lazy var handlers: [() throws(XemuError) -> Void] = {
        [
            op_00, op_01, op_02, op_03, op_04, op_05, op_06, op_07, op_08, op_09, op_0a, op_0b, op_0c, op_0d, op_0e, op_0f,
            op_10, op_11, op_12, op_13, op_14, op_15, op_16, op_17, op_18, op_19, op_1a, op_1b, op_1c, op_1d, op_1e, op_1f,
            op_20, op_21, op_22, op_23, op_24, op_25, op_26, op_27, op_28, op_29, op_2a, op_2b, op_2c, op_2d, op_2e, op_2f,
            op_30, op_31, op_32, op_33, op_34, op_35, op_36, op_37, op_38, op_39, op_3a, op_3b, op_3c, op_3d, op_3e, op_3f,
            op_40, op_41, op_42, op_43, op_44, op_45, op_46, op_47, op_48, op_49, op_4a, op_4b, op_4c, op_4d, op_4e, op_4f,
            op_50, op_51, op_52, op_53, op_54, op_55, op_56, op_57, op_58, op_59, op_5a, op_5b, op_5c, op_5d, op_5e, op_5f,
            op_60, op_61, op_62, op_63, op_64, op_65, op_66, op_67, op_68, op_69, op_6a, op_6b, op_6c, op_6d, op_6e, op_6f,
            op_70, op_71, op_72, op_73, op_74, op_75, op_76, op_77, op_78, op_79, op_7a, op_7b, op_7c, op_7d, op_7e, op_7f,
            op_80, op_81, op_82, op_83, op_84, op_85, op_86, op_87, op_88, op_89, op_8a, op_8b, op_8c, op_8d, op_8e, op_8f,
            op_90, op_91, op_92, op_93, op_94, op_95, op_96, op_97, op_98, op_99, op_9a, op_9b, op_9c, op_9d, op_9e, op_9f,
            op_a0, op_a1, op_a2, op_a3, op_a4, op_a5, op_a6, op_a7, op_a8, op_a9, op_aa, op_ab, op_ac, op_ad, op_ae, op_af,
            op_b0, op_b1, op_b2, op_b3, op_b4, op_b5, op_b6, op_b7, op_b8, op_b9, op_ba, op_bb, op_bc, op_bd, op_be, op_bf,
            op_c0, op_c1, op_c2, op_c3, op_c4, op_c5, op_c6, op_c7, op_c8, op_c9, op_ca, op_cb, op_cc, op_cd, op_ce, op_cf,
            op_d0, op_d1, op_d2, op_d3, op_d4, op_d5, op_d6, op_d7, op_d8, op_d9, op_da, op_db, op_dc, op_dd, op_de, op_df,
            op_e0, op_e1, op_e2, op_e3, op_e4, op_e5, op_e6, op_e7, op_e8, op_e9, op_ea, op_eb, op_ec, op_ed, op_ee, op_ef,
            op_f0, op_f1, op_f2, op_f3, op_f4, op_f5, op_f6, op_f7, op_f8, op_f9, op_fa, op_fb, op_fc, op_fd, op_fe, op_ff
        ]
    }()
    
    init(bus: Bus) {
        self.bus = bus
    }
    
    @inline(__always) func push8(_ value: u8) {
        startCycle(read: false)
        
        bus.write(value, at: u16(registers.s) + 0x100)
        registers.s &-= 1
        
        endCycle(read: false)
    }
    
    @inline(__always) func push16(_ value: u16) {
        push8(u8(value >> 8))
        push8(u8(value & 0xff))
    }

    @inline(__always) func pop8() -> u8 {
        startCycle(read: true)
        
        registers.s &+= 1
        let value = bus.read(at: u16(registers.s) + 0x100)
        
        endCycle(read: true)
        
        return value
    }
    
    @inline(__always) func pop16() -> u16 {
        let lo = pop8()
        let hi = pop8()

        return u16(hi: hi, lo: lo)
    }
    
    @discardableResult
    @inline(__always) func peek8() -> u8 {
        return read8(at: registers.pc)
    }

    @inline(__always) func read8() -> u8 {
        defer { registers.pc &+= 1 }
        
        return read8(at: registers.pc)
    }

    @inline(__always) func read16() -> u16 {
        defer { registers.pc &+= 2 }
        
        return read16(at: registers.pc)
    }

    @discardableResult
    @inline(__always) func read8(at address: u16) -> u8 {
        handleDma(address)
        
        startCycle(read: true)
        
        let value = bus.read(at: address)
        
        endCycle(read: true)
        
        return value
    }
    
    @inline(__always) func read16(at address: u16) -> u16 {
        let lo = read8(at: address)
        let hi = read8(at: address &+ 1)
        
        return u16(hi: hi, lo: lo)
    }
    
    @inline(__always) func write8(_ data: u8, at address: u16) {
        startCycle(read: false)
        
        bus.write(data, at: address)
        
        endCycle(read: false)
    }
    
    @inline(__always) func isCrossingPage(a: u16, b: u8) -> Bool {
        (a &+ u16(b)) & 0xff00 != a & 0xff00
    }
    
    @inline(__always) func isCrossingPage(a: u16, b: i8) -> Bool {
        (i32(a) &+ i32(b)) & 0xff00 != i32(a) & 0xff00
    }
    
    @inline(__always) func oamDma(_ value: u8) {
        state.oamDmaActive = true
        state.oamDmaOffset = value
        state.needsDmaHalt = true
    }
    
    @inline(__always) func dmcDma() {
        state.dmcDmaActive = true
        state.needsDmaHalt = true
        state.needsDmaDummyRead = true
    }
    
    @inline(__always) func stopDmcDma() {
        if state.dmcDmaActive {
            if state.needsDmaHalt {
                state.dmcDmaActive = false
                state.needsDmaHalt = false
                state.needsDmaDummyRead = false
            } else {
                state.dmcDmaAbort = true
            }
        }
    }

    @inline(__always) func startCycle(read: Bool) {
        clock += read ? 5 : 7
        cycles &+= 1

        bus.stepPPU(until: clock - ppuOffset)
        bus.stepAPU()
    }

    @inline(__always) func endCycle(read: Bool) {
        clock += read ? 7 : 5
        
        bus.stepPPU(until: clock - ppuOffset)

        state.nmiOldPending = state.nmiPending
        
        if !state.nmiOldSignal && state.nmiSignal {
            state.nmiPending = true
        }
        
        state.nmiOldSignal = state.nmiSignal
        
        state.irqOldPending = state.irqPending
        state.irqPending = state.irqSignal && !registers.p.interruptDisabled
    }
    
    public func reset(type: ResetType) {
        state.nmiSignal = false
        state.irqSignal = false
        
        state.oamDmaActive = false
        state.oamDmaOffset = 0
        
        state.dmcDmaActive = false
        state.dmcDmaAbort = false
        state.needsDmaHalt = false
        
        let lo = bus.read(at: InterruptType.reset.rawValue)
        let hi = bus.read(at: InterruptType.reset.rawValue + 1)
        registers.pc = u16(hi: hi, lo: lo)
        
        switch type {
            case .powerCycle:
                registers.a = 0
                registers.x = 0
                registers.y = 0
                registers.s = 0xfd
                registers.p = .init()
                
                state.irqPending = false
            case .reset:
                registers.p.interruptDisabled = true
                registers.s &-= 3
        }
        
        cycles = u64(bitPattern: -1)
        clock = 12
        
        for _ in 0..<8 {
            startCycle(read: true)
            endCycle(read: true)
        }
    }
    
    public func stepi() throws(XemuError) {
        state.opcode = read8()
        try handlers[Int(state.opcode)]()
        
        if state.irqOldPending || state.nmiOldPending {
            handleInterrupt()
        }
    }
    
    @inline(__always) private func op_a5() {
        handleZeroPageRead(lda)
    }
    
    @inline(__always) private func op_d0() {
        branch(shouldBranch: !registers.p.zero)
    }
    
    @inline(__always) private func op_4c() {
        jmpAbsolute()
    }
    
    @inline(__always) private func op_e8() {
        handleImplied(inx)
    }
    
    @inline(__always) private func op_10() {
        branch(shouldBranch: !registers.p.negative)
    }
    
    @inline(__always) private func op_c9() {
        handleImmediateRead(cmp)
    }
    
    @inline(__always) private func op_30() {
        branch(shouldBranch: registers.p.negative)
    }
    
    @inline(__always) private func op_f0() {
        branch(shouldBranch: registers.p.zero)
    }
    
    @inline(__always) private func op_24() {
        handleZeroPageRead(bit)
    }
    
    @inline(__always) private func op_85() {
        handleZeroPageWrite(sta)
    }
    
    @inline(__always) private func op_88() {
        handleImplied(dey)
    }
    
    @inline(__always) private func op_c8() {
        handleImplied(iny)
    }
    
    @inline(__always) private func op_a8() {
        handleImplied(tay)
    }
    
    @inline(__always) private func op_e6() {
        handleZeroPageModify(inc)
    }
    
    @inline(__always) private func op_b0() {
        branch(shouldBranch: registers.p.carry)
    }
    
    @inline(__always) private func op_bd() {
        handleAbsoluteIndexedXRead(lda)
    }
    
    @inline(__always) private func op_b5() {
        handleZeroPageIndexedXRead(lda)
    }
    
    @inline(__always) private func op_ad() {
        handleAbsoluteRead(lda)
    }
    
    @inline(__always) private func op_20() {
        jsr()
    }
    
    @inline(__always) private func op_4a() {
        handleAccumulatorModify(lsr)
    }
    
    @inline(__always) private func op_60() {
        handleImplied(rts)
    }
    
    @inline(__always) private func op_b1() {
        handleIndirectIndexedYRead(lda)
    }
    
    @inline(__always) private func op_29() {
        handleImmediateRead(and)
    }
    
    @inline(__always) private func op_9d() {
        handleAbsoluteIndexedXWrite(sta)
    }
    
    @inline(__always) private func op_8d() {
        handleAbsoluteWrite(sta)
    }
    
    @inline(__always) private func op_18() {
        handleImplied(clc)
    }
    
    @inline(__always) private func op_a9() {
        handleImmediateRead(lda)
    }
    
    @inline(__always) private func op_00() {
        brk()
    }
    
    @inline(__always) private func op_01() {
        handleIndexedIndirectXRead(ora)
    }
    
    @inline(__always) private func op_02() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_03() {
        handleIndexedIndirectXModify(slo)
    }
    
    @inline(__always) private func op_04() {
        handleZeroPageRead(nopRead)
    }
    
    @inline(__always) private func op_05() {
        handleZeroPageRead(ora)
    }
    
    @inline(__always) private func op_06() {
        handleZeroPageModify(asl)
    }
    
    @inline(__always) private func op_07() {
        handleZeroPageModify(slo)
    }
    
    @inline(__always) private func op_08() {
        php()
    }

    @inline(__always) private func op_09() {
        handleImmediateRead(ora)
    }
    
    @inline(__always) private func op_0a() {
        handleAccumulatorModify(asl)
    }
    
    @inline(__always) private func op_0b() {
        handleImmediateRead(anc)
    }
    
    @inline(__always) private func op_0c() {
        handleAbsoluteRead(nopRead)
    }
    
    @inline(__always) private func op_0d() {
        handleAbsoluteRead(ora)
    }
    
    @inline(__always) private func op_0e() {
        handleAbsoluteModify(asl)
    }
    
    @inline(__always) private func op_0f() {
        handleAbsoluteModify(slo)
    }
    
    @inline(__always) private func op_11() {
        handleIndirectIndexedYRead(ora)
    }
    
    @inline(__always) private func op_12() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_13() {
        handleIndirectIndexedYModify(slo)
    }
    
    @inline(__always) private func op_14() {
        handleZeroPageIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_15() {
        handleZeroPageIndexedXRead(ora)
    }
    
    @inline(__always) private func op_16() {
        handleZeroPageIndexedXModify(asl)
    }
    
    @inline(__always) private func op_17() {
        handleZeroPageIndexedXModify(slo)
    }
    
    @inline(__always) private func op_19() {
        handleAbsoluteIndexedYRead(ora)
    }
    
    @inline(__always) private func op_1a() {
        handleImplied(nop)
    }
    
    @inline(__always) private func op_1b() {
        handleAbsoluteIndexedYModify(slo)
    }
    
    @inline(__always) private func op_1c() {
        handleAbsoluteIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_1d() {
        handleAbsoluteIndexedXRead(ora)
    }
    
    @inline(__always) private func op_1e() {
        handleAbsoluteIndexedXModify(asl)
    }
    
    @inline(__always) private func op_1f() {
        handleAbsoluteIndexedXModify(slo)
    }
    
    @inline(__always) private func op_21() {
        handleIndexedIndirectXRead(and)
    }
    
    @inline(__always) private func op_22() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_23() {
        handleIndexedIndirectXModify(rla)
    }
    
    @inline(__always) private func op_25() {
        handleZeroPageRead(and)
    }
    
    @inline(__always) private func op_26() {
        handleZeroPageModify(rol)
    }
    
    @inline(__always) private func op_27() {
        handleZeroPageModify(rla)
    }
    
    @inline(__always) private func op_28() {
        plp()
    }
    
    @inline(__always) private func op_2a() {
        handleAccumulatorModify(rol)
    }
    
    @inline(__always) private func op_2b() {
        handleImmediateRead(anc)
    }
    
    @inline(__always) private func op_2c() {
        handleAbsoluteRead(bit)
    }
    
    @inline(__always) private func op_2d() {
        handleAbsoluteRead(and)
    }
    
    @inline(__always) private func op_2e() {
        handleAbsoluteModify(rol)
    }
    
    @inline(__always) private func op_2f() {
        handleAbsoluteModify(rla)
    }
    
    @inline(__always) private func op_31() {
        handleIndirectIndexedYRead(and)
    }
    
    @inline(__always) private func op_32() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_33() {
        handleIndirectIndexedYModify(rla)
    }
    
    @inline(__always) private func op_34() {
        handleZeroPageIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_35() {
        handleZeroPageIndexedXRead(and)
    }
    
    @inline(__always) private func op_36() {
        handleZeroPageIndexedXModify(rol)
    }
    
    @inline(__always) private func op_37() {
        handleZeroPageIndexedXModify(rla)
    }
    
    @inline(__always) private func op_38() {
        handleImplied(sec)
    }
    
    @inline(__always) private func op_39() {
        handleAbsoluteIndexedYRead(and)
    }
    
    @inline(__always) private func op_3a() {
        handleImplied(nop)
    }
    
    @inline(__always) private func op_3b() {
        handleAbsoluteIndexedYModify(rla)
    }
    
    @inline(__always) private func op_3c() {
        handleAbsoluteIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_3d() {
        handleAbsoluteIndexedXRead(and)
    }
    
    @inline(__always) private func op_3e() {
        handleAbsoluteIndexedXModify(rol)
    }
    
    @inline(__always) private func op_3f() {
        handleAbsoluteIndexedXModify(rla)
    }
    
    @inline(__always) private func op_40() {
        handleImplied(rti)
    }
    
    @inline(__always) private func op_41() {
        handleIndexedIndirectXRead(eor)
    }
    
    @inline(__always) private func op_42() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_43() {
        handleIndexedIndirectXModify(sre)
    }
    
    @inline(__always) private func op_44() {
        handleZeroPageRead(nopRead)
    }
    
    @inline(__always) private func op_45() {
        handleZeroPageRead(eor)
    }
    
    @inline(__always) private func op_46() {
        handleZeroPageModify(lsr)
    }
    
    @inline(__always) private func op_47() {
        handleZeroPageModify(sre)
    }
    
    @inline(__always) private func op_48() {
        pha()
    }
    
    @inline(__always) private func op_49() {
        handleImmediateRead(eor)
    }
    
    @inline(__always) private func op_4b() {
        handleImmediateRead(alr)
    }
    
    @inline(__always) private func op_4d() {
        handleAbsoluteRead(eor)
    }
    
    @inline(__always) private func op_4e() {
        handleAbsoluteModify(lsr)
    }
    
    @inline(__always) private func op_4f() {
        handleAbsoluteModify(sre)
    }
    
    @inline(__always) private func op_50() {
        branch(shouldBranch: !registers.p.overflow)
    }
    
    @inline(__always) private func op_51() {
        handleIndirectIndexedYRead(eor)
    }
    
    @inline(__always) private func op_52() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_53() {
        handleIndirectIndexedYModify(sre)
    }
    
    @inline(__always) private func op_54() {
        handleZeroPageIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_55() {
        handleZeroPageIndexedXRead(eor)
    }
    
    @inline(__always) private func op_56() {
        handleZeroPageIndexedXModify(lsr)
    }
    
    @inline(__always) private func op_57() {
        handleZeroPageIndexedXModify(sre)
    }
    
    @inline(__always) private func op_58() {
        handleImplied(cli)
    }
    
    @inline(__always) private func op_59() {
        handleAbsoluteIndexedYRead(eor)
    }
    
    @inline(__always) private func op_5a() {
        handleImplied(nop)
    }
    
    @inline(__always) private func op_5b() {
        handleAbsoluteIndexedYModify(sre)
    }
    
    @inline(__always) private func op_5c() {
        handleAbsoluteIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_5d() {
        handleAbsoluteIndexedXRead(eor)
    }
    
    @inline(__always) private func op_5e() {
        handleAbsoluteIndexedXModify(lsr)

    }
    
    @inline(__always) private func op_5f() {
        handleAbsoluteIndexedXModify(sre)
    }
    
    @inline(__always) private func op_61() {
        handleIndexedIndirectXRead(adc)
    }
    
    @inline(__always) private func op_62() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_63() {
        handleIndexedIndirectXModify(rra)
    }
    
    @inline(__always) private func op_64() {
        handleZeroPageRead(nopRead)
    }
    
    @inline(__always) private func op_65() {
        handleZeroPageRead(adc)
    }
    
    @inline(__always) private func op_66() {
        handleZeroPageModify(ror)
    }
    
    @inline(__always) private func op_67() {
        handleZeroPageModify(rra)
    }
    
    @inline(__always) private func op_68() {
        pla()
    }
    
    @inline(__always) private func op_69() {
        handleImmediateRead(adc)
    }
    
    @inline(__always) private func op_6a() {
        handleAccumulatorModify(ror)
    }
    
    @inline(__always) private func op_6b() {
        handleImmediateRead(arr)
    }
    
    @inline(__always) private func op_6c() {
        jmpIndirect()
    }
    
    @inline(__always) private func op_6d() {
        handleAbsoluteRead(adc)
    }
    
    @inline(__always) private func op_6e() {
        handleAbsoluteModify(ror)
    }
    
    @inline(__always) private func op_6f() {
        handleAbsoluteModify(rra)
    }
    
    @inline(__always) private func op_70() {
        branch(shouldBranch: registers.p.overflow)
    }
    
    @inline(__always) private func op_71() {
        handleIndirectIndexedYRead(adc)
    }
    
    @inline(__always) private func op_72() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_73() {
        handleIndirectIndexedYModify(rra)
    }
    
    @inline(__always) private func op_74() {
        handleZeroPageIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_75() {
        handleZeroPageIndexedXRead(adc)
    }
    
    @inline(__always) private func op_76() {
        handleZeroPageIndexedXModify(ror)
    }
    
    @inline(__always) private func op_77() {
        handleZeroPageIndexedXModify(rra)
    }
    
    @inline(__always) private func op_78() {
        handleImplied(sei)
    }
    
    @inline(__always) private func op_79() {
        handleAbsoluteIndexedYRead(adc)
    }
    
    @inline(__always) private func op_7a() {
        handleImplied(nop)
    }
    
    @inline(__always) private func op_7b() {
        handleAbsoluteIndexedYModify(rra)
    }
    
    @inline(__always) private func op_7c() {
        handleAbsoluteIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_7d() {
        handleAbsoluteIndexedXRead(adc)
    }
    
    @inline(__always) private func op_7e() {
        handleAbsoluteIndexedXModify(ror)
    }
    
    @inline(__always) private func op_7f() {
        handleAbsoluteIndexedXModify(rra)
    }
    
    @inline(__always) private func op_80() {
        handleImmediateRead(nopRead)
    }
    
    @inline(__always) private func op_81() {
        handleIndexedIndirectXWrite(sta)
    }
    
    @inline(__always) private func op_82() {
        handleImmediateRead(nopRead(_:))
    }
    
    @inline(__always) private func op_83() {
        handleIndexedIndirectXWrite(sax)
    }
    
    @inline(__always) private func op_84() {
        handleZeroPageWrite(sty)
    }
    
    @inline(__always) private func op_86() {
        handleZeroPageWrite(stx)
    }
    
    @inline(__always) private func op_87() {
        handleZeroPageWrite(sax)
    }
    
    @inline(__always) private func op_89() {
        handleImmediateRead(nopRead)
    }
    
    @inline(__always) private func op_8a() {
        handleImplied(txa)
    }
    
    @inline(__always) private func op_8b() {
        handleImmediateRead(xaa)
    }
    
    @inline(__always) private func op_8c() {
        handleAbsoluteWrite(sty)
    }
    
    @inline(__always) private func op_8e() {
        handleAbsoluteWrite(stx)
    }
    
    @inline(__always) private func op_8f() {
        handleAbsoluteWrite(sax)
    }
    
    @inline(__always) private func op_90() {
        branch(shouldBranch: !registers.p.carry)
    }
    
    @inline(__always) private func op_91() {
        handleIndirectIndexedYWrite(sta)
    }
    
    @inline(__always) private func op_92() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_93() {
        shaz()
    }
    
    @inline(__always) private func op_94() {
        handleZeroPageIndexedXWrite(sty)
    }
    
    @inline(__always) private func op_95() {
        handleZeroPageIndexedXWrite(sta)
    }
    
    @inline(__always) private func op_96() {
        handleZeroPageIndexedYWrite(stx)
    }
    
    @inline(__always) private func op_97() {
        handleZeroPageIndexedYWrite(sax)
    }
    
    @inline(__always) private func op_98() {
        handleImplied(tya)
    }
    
    @inline(__always) private func op_99() {
        handleAbsoluteIndexedYWrite(sta)
    }
    
    @inline(__always) private func op_9a() {
        handleImplied(txs)
    }
    
    @inline(__always) private func op_9b() {
        tas()
    }
    
    @inline(__always) private func op_9c() {
        shy()
    }
    
    @inline(__always) private func op_9e() {
        shx()
    }
    
    @inline(__always) private func op_9f() {
        shaa()
    }
    
    @inline(__always) private func op_a0() {
        handleImmediateRead(ldy)
    }
    
    @inline(__always) private func op_a1() {
        handleIndexedIndirectXRead(lda)
    }
    
    @inline(__always) private func op_a2() {
        handleImmediateRead(ldx)
    }
    
    @inline(__always) private func op_a3() {
        handleIndexedIndirectXRead(lax)
    }
    
    @inline(__always) private func op_a4() {
        handleZeroPageRead(ldy)
    }
    
    @inline(__always) private func op_a6() {
        handleZeroPageRead(ldx)
    }
    
    @inline(__always) private func op_a7() {
        handleZeroPageRead(lax)
    }
    
    @inline(__always) private func op_aa() {
        handleImplied(tax)
    }
    
    @inline(__always) private func op_ab() {
        handleImmediateRead(lax)
    }
    
    @inline(__always) private func op_ac() {
        handleAbsoluteRead(ldy)
    }
    
    @inline(__always) private func op_ae() {
        handleAbsoluteRead(ldx)

    }
    
    @inline(__always) private func op_af() {
        handleAbsoluteRead(lax)
    }
    
    @inline(__always) private func op_b2() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_b3() {
        handleIndirectIndexedYRead(lax)
    }
    
    @inline(__always) private func op_b4() {
        handleZeroPageIndexedXRead(ldy)
    }
    
    @inline(__always) private func op_b6() {
        handleZeroPageIndexedYRead(ldx)
    }
    
    @inline(__always) private func op_b7() {
        handleZeroPageIndexedYRead(lax)
    }
    
    @inline(__always) private func op_b8() {
        handleImplied(clv)
    }
    
    @inline(__always) private func op_b9() {
        handleAbsoluteIndexedYRead(lda)
    }
    
    @inline(__always) private func op_ba() {
        handleImplied(tsx)
    }
    
    @inline(__always) private func op_bb() {
        handleAbsoluteIndexedYRead(las)
    }
    
    @inline(__always) private func op_bc() {
        handleAbsoluteIndexedXRead(ldy)
    }
    
    @inline(__always) private func op_be() {
        handleAbsoluteIndexedYRead(ldx)
    }
    
    @inline(__always) private func op_bf() {
        handleAbsoluteIndexedYRead(lax)
    }
    
    @inline(__always) private func op_c0() {
        handleImmediateRead(cpy)
    }
    
    @inline(__always) private func op_c1() {
        handleIndexedIndirectXRead(cmp)
    }
    
    @inline(__always) private func op_c2() {
        handleImmediateRead(nopRead)
    }
    
    @inline(__always) private func op_c3() {
        handleIndexedIndirectXModify(dcp)
    }
    
    @inline(__always) private func op_c4() {
        handleZeroPageRead(cpy)
    }
    
    @inline(__always) private func op_c5() {
        handleZeroPageRead(cmp)
    }
    
    @inline(__always) private func op_c6() {
        handleZeroPageModify(dec)
    }
    
    @inline(__always) private func op_c7() {
        handleZeroPageModify(dcp)
    }
    
    @inline(__always) private func op_ca() {
        handleImplied(dex)
    }
    
    @inline(__always) private func op_cb() {
        handleImmediateRead(axs)
    }
    
    @inline(__always) private func op_cc() {
        handleAbsoluteRead(cpy)
    }
    
    @inline(__always) private func op_cd() {
        handleAbsoluteRead(cmp)
    }
    
    @inline(__always) private func op_ce() {
        handleAbsoluteModify(dec)
    }
    
    @inline(__always) private func op_cf() {
        handleAbsoluteModify(dcp)
    }
    
    @inline(__always) private func op_d1() {
        handleIndirectIndexedYRead(cmp)
    }
    
    @inline(__always) private func op_d2() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_d3() {
        handleIndirectIndexedYModify(dcp)
    }
    
    @inline(__always) private func op_d4() {
        handleZeroPageIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_d5() {
        handleZeroPageIndexedXRead(cmp)
    }
    
    @inline(__always) private func op_d6() {
        handleZeroPageIndexedXModify(dec)
    }
    
    @inline(__always) private func op_d7() {
        handleZeroPageIndexedXModify(dcp)
    }
    
    @inline(__always) private func op_d8() {
        handleImplied(cld)
    }
    
    @inline(__always) private func op_d9() {
        handleAbsoluteIndexedYRead(cmp)
    }
    
    @inline(__always) private func op_da() {
        handleImplied(nop)
    }
    
    @inline(__always) private func op_db() {
        handleAbsoluteIndexedYModify(dcp)
    }
    
    @inline(__always) private func op_dc() {
        handleAbsoluteIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_dd() {
        handleAbsoluteIndexedXRead(cmp)
    }
    
    @inline(__always) private func op_de() {
        handleAbsoluteIndexedXModify(dec)
    }
    
    @inline(__always) private func op_df() {
        handleAbsoluteIndexedXModify(dcp)
    }
    
    @inline(__always) private func op_e0() {
        handleImmediateRead(cpx)
    }
    
    @inline(__always) private func op_e1() {
        handleIndexedIndirectXRead(sbc)
    }
    
    @inline(__always) private func op_e2() {
        handleImmediateRead(nopRead)
    }
    
    @inline(__always) private func op_e3() {
        handleIndexedIndirectXModify(isc)
    }
    
    @inline(__always) private func op_e4() {
        handleZeroPageRead(cpx)
    }
    
    @inline(__always) private func op_e5() {
        handleZeroPageRead(sbc)
    }
    
    @inline(__always) private func op_e7() {
        handleZeroPageModify(isc)
    }
    
    @inline(__always) private func op_e9() {
        handleImmediateRead(sbc)
    }
    
    @inline(__always) private func op_ea() {
        handleImplied(nop)
    }
    
    @inline(__always) private func op_eb() {
        handleImmediateRead(sbc)
    }
    
    @inline(__always) private func op_ec() {
        handleAbsoluteRead(cpx)
    }
    
    @inline(__always) private func op_ed() {
        handleAbsoluteRead(sbc)
    }
    
    @inline(__always) private func op_ee() {
        handleAbsoluteModify(inc)
    }
    
    @inline(__always) private func op_ef() {
        handleAbsoluteModify(isc)
    }
    
    @inline(__always) private func op_f1() {
        handleIndirectIndexedYRead(sbc)
    }
    
    @inline(__always) private func op_f2() throws(XemuError) {
        throw .emulatorHalted
    }
    
    @inline(__always) private func op_f3() {
        handleIndirectIndexedYModify(isc)
    }
    
    @inline(__always) private func op_f4() {
        handleZeroPageIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_f5() {
        handleZeroPageIndexedXRead(sbc)
    }
    
    @inline(__always) private func op_f6() {
        handleZeroPageIndexedXModify(inc)
    }
    
    @inline(__always) private func op_f7() {
        handleZeroPageIndexedXModify(isc)
    }
    
    @inline(__always) private func op_f8() {
        handleImplied(sed)
    }
    
    @inline(__always) private func op_f9() {
        handleAbsoluteIndexedYRead(sbc)
    }
    
    @inline(__always) private func op_fa() {
        handleImplied(nop)
    }
    
    @inline(__always) private func op_fb() {
        handleAbsoluteIndexedYModify(isc)
    }
    
    @inline(__always) private func op_fc() {
        handleAbsoluteIndexedXRead(nopRead)
    }
    
    @inline(__always) private func op_fd() {
        handleAbsoluteIndexedXRead(sbc)
    }
    
    @inline(__always) private func op_fe() {
        handleAbsoluteIndexedXModify(inc)
    }
    
    @inline(__always) private func op_ff() {
        handleAbsoluteIndexedXModify(isc)
    }
    
    enum CodingKeys: String, CodingKey {
        case registers
        case state
    }
}

extension MOS6502 {
    public func getRegisters() -> [RegisterInfo] {
        [
            .regular("A", size: 1, value: .u8(registers.a)),
            .regular("X", size: 1, value: .u8(registers.x)),
            .regular("Y", size: 1, value: .u8(registers.y)),
            .stack("S", size: 1, value: .u8(registers.s)),
            .programCounter("PC", size: 2, value: .u16(registers.pc)),
            .flags(
                "P",
                size: 1,
                flags: [
                    .init(mask: UInt(Flags.CARRY_MASK), acronym: "C", name: "Carry"),
                    .init(mask: UInt(Flags.ZERO_MASK), acronym: "Z", name: "Zero"),
                    .init(mask: UInt(Flags.INTERRUPT_DISABLED_MASK), acronym: "I", name: "Interrupt"),
                    .init(mask: UInt(Flags.DECIMAL_MASK), acronym: "D", name: "Decimal"),
                    .init(mask: 0b0001_0000, acronym: "B", name: "Break"),
                    .init(mask: 0b0010_0000, acronym: "1", name: "Always"),
                    .init(mask: UInt(Flags.OVERFLOW_MASK), acronym: "V", name: "Overflow"),
                    .init(mask: UInt(Flags.NEGATIVE_MASK), acronym: "N", name: "Negative"),
                ],
                value: .u8(registers.p.value())
            )
        ]
    }
    
    public func setRegister(name: String, value: u64) {
        switch name.uppercased() {
            case "A":
                registers.a = u8(value & 0xff)
            case "X":
                registers.x = u8(value & 0xff)
            case "Y":
                registers.y = u8(value & 0xff)
            case "S":
                registers.s = u8(value & 0xff)
            case "PC":
                registers.pc = u16(value & 0xffff)
            case "P":
                registers.p = .init(u8(value & 0xff))
            default:
                print("Unknown register: \(name) = \(value)")
        }
    }
}
