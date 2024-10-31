//import XemuDebugger
//import XemuFoundation
//
//public class MOS6502Fast: Codable {
//    var registers = MOS6502.Registers()
//    var state = MOS6502.CpuState()
//
//    weak var bus: Bus!
//    
//    init(bus: Bus) {
//        self.bus = bus
//    }
//    
//    @inline(__always) func read8() -> u8 {
//        defer { registers.pc &+= 1 }
//        
//        return bus.read(at: registers.pc)
//    }
//    
//    @inline(__always) func push(_ value: u8) {
//        bus.writeStack(value, at: registers.s)
//        registers.s &-= 1
//    }
//    
//    @inline(__always) func pop() -> u8 {
//        registers.s &+= 1
//        return bus.readStack(at: registers.s)
//    }
//    
//    @inline(__always) func handleImmediate(a: ReadOpcodeHandler) {
//        state.lo = read8()
//    }
//    
//    @inline(__always) func zeroPage() {
//        state.lo = read8()
//        state.temp = bus.read(at: u16(state.lo))
//    }
//    
//    @inline(__always) func zeroPage(indexed index: u8) {
//        state.lo = read8()
//        state.temp = bus.read(at: u16(state.lo &+ index))
//    }
//    
//    @inline(__always) func absolute() {
//        state.lo = read8()
//        state.hi = read8()
//        state.temp = bus.read(at: state.data)
//    }
//    
//    @inline(__always) func absolute(indexed index: u8) -> Bool {
//        state.lo = read8()
//        state.hi = read8()
//        let address = state.data &+ u16(index)
//        state.temp = bus.read(at: address)
//        
//        return address & 0xFF != state.hi
//    }
//    
//    @inline(__always) func indirect(x: u8) {
//        
//    }
//    
//    @inline(__always) func indirect(y: u8) -> Bool {
//        false
//    }
//    
//    private func handleInterrupt() -> Int {
//        0
//    }
//    
//    private func handleReset() -> Int {
//        return 7
//    }
//
//    public func clock() throws(XemuError) -> Int {
//        if state.nmiPending {
//            state.servicing = .nmi
//        } else if state.irqPending {
//            state.servicing = .irq
//        }
//        
//        switch state.servicing {
//            case .some(.irq), .some(.nmi):
//                return handleInterrupt()
//            case .some(.reset):
//                return handleReset()
//            default:
//                break
//        }
//        
//        state.opcode = read8()
//        
//        return switch state.opcode {
//            case 0xa5: op_a5()
//            case 0xd0: op_d0()
//            case 0x4c: op_4c()
//            case 0xe8: op_e8()
//            case 0x10: op_10()
//            case 0xc9: op_c9()
//            case 0x30: op_30()
//            case 0xf0: op_f0()
//            case 0x24: op_24()
//            case 0x85: op_85()
//            case 0x88: op_88()
//            case 0xc8: op_c8()
//            case 0xa8: op_a8()
//            case 0xe6: op_e6()
//            case 0xb0: op_b0()
//            case 0xbd: op_bd()
//            case 0xb5: op_b5()
//            case 0xad: op_ad()
//            case 0x20: op_20()
//            case 0x4a: op_4a()
//            case 0x60: op_60()
//            case 0xb1: op_b1()
//            case 0x29: op_29()
//            case 0x9d: op_9d()
//            case 0x8d: op_8d()
//            case 0x18: op_18()
//            case 0xa9: op_a9()
//            case 0x00: op_00()
//            case 0x01: op_01()
//            case 0x02: try op_02()
//            case 0x03: op_03()
//            case 0x04: op_04()
//            case 0x05: op_05()
//            case 0x06: op_06()
//            case 0x07: op_07()
//            case 0x08: op_08()
//            case 0x09: op_09()
//            case 0x0a: op_0a()
//            case 0x0b: op_0b()
//            case 0x0c: op_0c()
//            case 0x0d: op_0d()
//            case 0x0e: op_0e()
//            case 0x0f: op_0f()
//            case 0x11: op_11()
//            case 0x12: try op_12()
//            case 0x13: op_13()
//            case 0x14: op_14()
//            case 0x15: op_15()
//            case 0x16: op_16()
//            case 0x17: op_17()
//            case 0x19: op_19()
//            case 0x1a: op_1a()
//            case 0x1b: op_1b()
//            case 0x1c: op_1c()
//            case 0x1d: op_1d()
//            case 0x1e: op_1e()
//            case 0x1f: op_1f()
//            case 0x21: op_21()
//            case 0x22: try op_22()
//            case 0x23: op_23()
//            case 0x25: op_25()
//            case 0x26: op_26()
//            case 0x27: op_27()
//            case 0x28: op_28()
//            case 0x2a: op_2a()
//            case 0x2b: op_2b()
//            case 0x2c: op_2c()
//            case 0x2d: op_2d()
//            case 0x2e: op_2e()
//            case 0x2f: op_2f()
//            case 0x31: op_31()
//            case 0x32: try op_32()
//            case 0x33: op_33()
//            case 0x34: op_34()
//            case 0x35: op_35()
//            case 0x36: op_36()
//            case 0x37: op_37()
//            case 0x38: op_38()
//            case 0x39: op_39()
//            case 0x3a: op_3a()
//            case 0x3b: op_3b()
//            case 0x3c: op_3c()
//            case 0x3d: op_3d()
//            case 0x3e: op_3e()
//            case 0x3f: op_3f()
//            case 0x40: op_40()
//            case 0x41: op_41()
//            case 0x42: try op_42()
//            case 0x43: op_43()
//            case 0x44: op_44()
//            case 0x45: op_45()
//            case 0x46: op_46()
//            case 0x47: op_47()
//            case 0x48: op_48()
//            case 0x49: op_49()
//            case 0x4b: op_4b()
//            case 0x4d: op_4d()
//            case 0x4e: op_4e()
//            case 0x4f: op_4f()
//            case 0x50: op_50()
//            case 0x51: op_51()
//            case 0x52: try op_52()
//            case 0x53: op_53()
//            case 0x54: op_54()
//            case 0x55: op_55()
//            case 0x56: op_56()
//            case 0x57: op_57()
//            case 0x58: op_58()
//            case 0x59: op_59()
//            case 0x5a: op_5a()
//            case 0x5b: op_5b()
//            case 0x5c: op_5c()
//            case 0x5d: op_5d()
//            case 0x5e: op_5e()
//            case 0x5f: op_5f()
//            case 0x61: op_61()
//            case 0x62: try op_62()
//            case 0x63: op_63()
//            case 0x64: op_64()
//            case 0x65: op_65()
//            case 0x66: op_66()
//            case 0x67: op_67()
//            case 0x68: op_68()
//            case 0x69: op_69()
//            case 0x6a: op_6a()
//            case 0x6b: op_6b()
//            case 0x6c: op_6c()
//            case 0x6d: op_6d()
//            case 0x6e: op_6e()
//            case 0x6f: op_6f()
//            case 0x70: op_70()
//            case 0x71: op_71()
//            case 0x72: try op_72()
//            case 0x73: op_73()
//            case 0x74: op_74()
//            case 0x75: op_75()
//            case 0x76: op_76()
//            case 0x77: op_77()
//            case 0x78: op_78()
//            case 0x79: op_79()
//            case 0x7a: op_7a()
//            case 0x7b: op_7b()
//            case 0x7c: op_7c()
//            case 0x7d: op_7d()
//            case 0x7e: op_7e()
//            case 0x7f: op_7f()
//            case 0x80: op_80()
//            case 0x81: op_81()
//            case 0x82: op_82()
//            case 0x83: op_83()
//            case 0x84: op_84()
//            case 0x86: op_86()
//            case 0x87: op_87()
//            case 0x89: op_89()
//            case 0x8a: op_8a()
//            case 0x8b: op_8b()
//            case 0x8c: op_8c()
//            case 0x8e: op_8e()
//            case 0x8f: op_8f()
//            case 0x90: op_90()
//            case 0x91: op_91()
//            case 0x92: try op_92()
//            case 0x93: op_93()
//            case 0x94: op_94()
//            case 0x95: op_95()
//            case 0x96: op_96()
//            case 0x97: op_97()
//            case 0x98: op_98()
//            case 0x99: op_99()
//            case 0x9a: op_9a()
//            case 0x9b: op_9b()
//            case 0x9c: op_9c()
//            case 0x9e: op_9e()
//            case 0x9f: op_9f()
//            case 0xa0: op_a0()
//            case 0xa1: op_a1()
//            case 0xa2: op_a2()
//            case 0xa3: op_a3()
//            case 0xa4: op_a4()
//            case 0xa6: op_a6()
//            case 0xa7: op_a7()
//            case 0xaa: op_aa()
//            case 0xab: op_ab()
//            case 0xac: op_ac()
//            case 0xae: op_ae()
//            case 0xaf: op_af()
//            case 0xb2: try op_b2()
//            case 0xb3: op_b3()
//            case 0xb4: op_b4()
//            case 0xb6: op_b6()
//            case 0xb7: op_b7()
//            case 0xb8: op_b8()
//            case 0xb9: op_b9()
//            case 0xba: op_ba()
//            case 0xbb: op_bb()
//            case 0xbc: op_bc()
//            case 0xbe: op_be()
//            case 0xbf: op_bf()
//            case 0xc0: op_c0()
//            case 0xc1: op_c1()
//            case 0xc2: op_c2()
//            case 0xc3: op_c3()
//            case 0xc4: op_c4()
//            case 0xc5: op_c5()
//            case 0xc6: op_c6()
//            case 0xc7: op_c7()
//            case 0xca: op_ca()
//            case 0xcb: op_cb()
//            case 0xcc: op_cc()
//            case 0xcd: op_cd()
//            case 0xce: op_ce()
//            case 0xcf: op_cf()
//            case 0xd1: op_d1()
//            case 0xd2: try op_d2()
//            case 0xd3: op_d3()
//            case 0xd4: op_d4()
//            case 0xd5: op_d5()
//            case 0xd6: op_d6()
//            case 0xd7: op_d7()
//            case 0xd8: op_d8()
//            case 0xd9: op_d9()
//            case 0xda: op_da()
//            case 0xdb: op_db()
//            case 0xdc: op_dc()
//            case 0xdd: op_dd()
//            case 0xde: op_de()
//            case 0xdf: op_df()
//            case 0xe0: op_e0()
//            case 0xe1: op_e1()
//            case 0xe2: op_e2()
//            case 0xe3: op_e3()
//            case 0xe4: op_e4()
//            case 0xe5: op_e5()
//            case 0xe7: op_e7()
//            case 0xe9: op_e9()
//            case 0xea: op_ea()
//            case 0xeb: op_eb()
//            case 0xec: op_ec()
//            case 0xed: op_ed()
//            case 0xee: op_ee()
//            case 0xef: op_ef()
//            case 0xf1: op_f1()
//            case 0xf2: try op_f2()
//            case 0xf3: op_f3()
//            case 0xf4: op_f4()
//            case 0xf5: op_f5()
//            case 0xf6: op_f6()
//            case 0xf7: op_f7()
//            case 0xf8: op_f8()
//            case 0xf9: op_f9()
//            case 0xfa: op_fa()
//            case 0xfb: op_fb()
//            case 0xfc: op_fc()
//            case 0xfd: op_fd()
//            case 0xfe: op_fe()
//            case 0xff: op_ff()
//            default: 0
//        }
//    }
//    
//    @inline(__always) private func op_a5() -> Int {
//        zeroPage()
//        lda(state.lo)
//        return 3
//    }
//    
//    @inline(__always) private func op_d0() -> Int {
//        branch()
//    }
//    
//    @inline(__always) private func op_4c() -> Int {
//        jmpAbsolute()
//    }
//    
//    @inline(__always) private func op_e8() -> Int {
//        handleImplied(inx)
//    }
//    
//    @inline(__always) private func op_10() -> Int {
//        branch()
//    }
//    
//    @inline(__always) private func op_c9() -> Int {
//        handleImmediateRead(cmp)
//    }
//    
//    @inline(__always) private func op_30() -> Int {
//        branch()
//    }
//    
//    @inline(__always) private func op_f0() -> Int {
//        branch()
//    }
//    
//    @inline(__always) private func op_24() -> Int {
//        handleZeroPageRead(bit)
//    }
//    
//    @inline(__always) private func op_85() -> Int {
//        handleZeroPageWrite(sta)
//    }
//    
//    @inline(__always) private func op_88() -> Int {
//        handleImplied(dey)
//    }
//    
//    @inline(__always) private func op_c8() -> Int {
//        handleImplied(iny)
//    }
//    
//    @inline(__always) private func op_a8() -> Int {
//        handleImplied(tay)
//    }
//    
//    @inline(__always) private func op_e6() -> Int {
//        handleZeroPageModify(inc)
//    }
//    
//    @inline(__always) private func op_b0() -> Int {
//        branch()
//    }
//    
//    @inline(__always) private func op_bd() -> Int {
//        handleAbsoluteIndexedXRead(lda)
//    }
//    
//    @inline(__always) private func op_b5() -> Int {
//        handleZeroPageIndexedXRead(lda)
//    }
//    
//    @inline(__always) private func op_ad() -> Int {
//        handleAbsoluteRead(lda)
//    }
//    
//    @inline(__always) private func op_20() -> Int {
//        jsr()
//    }
//    
//    @inline(__always) private func op_4a() -> Int {
//        handleAccumulatorModify(lsr)
//    }
//    
//    @inline(__always) private func op_60() -> Int {
//        rts()
//    }
//    
//    @inline(__always) private func op_b1() -> Int {
//        handleIndirectIndexedYRead(lda)
//    }
//    
//    @inline(__always) private func op_29() -> Int {
//        handleImmediateRead(and)
//    }
//    
//    @inline(__always) private func op_9d() -> Int {
//        handleAbsoluteIndexedXWrite(sta)
//    }
//    
//    @inline(__always) private func op_8d() -> Int {
//        handleAbsoluteWrite(sta)
//    }
//    
//    @inline(__always) private func op_18() -> Int {
//        handleImplied(clc)
//    }
//    
//    @inline(__always) private func op_a9() -> Int {
//        handleImmediateRead(lda)
//    }
//    
//    @inline(__always) private func op_00() -> Int {
//        brk()
//    }
//    
//    @inline(__always) private func op_01() -> Int {
//        handleIndexedIndirectXRead(ora)
//    }
//    
//    @inline(__always) private func op_02() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_03() -> Int {
//        handleIndexedIndirectXModify(slo)
//    }
//    
//    @inline(__always) private func op_04() -> Int {
//        handleZeroPageRead(nopRead)
//    }
//    
//    @inline(__always) private func op_05() -> Int {
//        handleZeroPageRead(ora)
//    }
//    
//    @inline(__always) private func op_06() -> Int {
//        handleZeroPageModify(asl)
//    }
//    
//    @inline(__always) private func op_07() -> Int {
//        handleZeroPageModify(slo)
//    }
//    
//    @inline(__always) private func op_08() -> Int {
//        php()
//    }
//
//    @inline(__always) private func op_09() -> Int {
//        handleImmediateRead(ora)
//    }
//    
//    @inline(__always) private func op_0a() -> Int {
//        handleAccumulatorModify(asl)
//    }
//    
//    @inline(__always) private func op_0b() -> Int {
//        handleImmediateRead(anc)
//    }
//    
//    @inline(__always) private func op_0c() -> Int {
//        handleAbsoluteRead(nopRead)
//    }
//    
//    @inline(__always) private func op_0d() -> Int {
//        handleAbsoluteRead(ora)
//    }
//    
//    @inline(__always) private func op_0e() -> Int {
//        handleAbsoluteModify(asl)
//    }
//    
//    @inline(__always) private func op_0f() -> Int {
//        handleAbsoluteModify(slo)
//    }
//    
//    @inline(__always) private func op_11() -> Int {
//        handleIndirectIndexedYRead(ora)
//    }
//    
//    @inline(__always) private func op_12() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_13() -> Int {
//        handleIndirectIndexedYModify(slo)
//    }
//    
//    @inline(__always) private func op_14() -> Int {
//        handleZeroPageIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_15() -> Int {
//        handleZeroPageIndexedXRead(ora)
//    }
//    
//    @inline(__always) private func op_16() -> Int {
//        handleZeroPageIndexedXModify(asl)
//    }
//    
//    @inline(__always) private func op_17() -> Int {
//        handleZeroPageIndexedXModify(slo)
//    }
//    
//    @inline(__always) private func op_19() -> Int {
//        handleAbsoluteIndexedYRead(ora)
//    }
//    
//    @inline(__always) private func op_1a() -> Int {
//        handleImplied(nop)
//    }
//    
//    @inline(__always) private func op_1b() -> Int {
//        handleAbsoluteIndexedYModify(slo)
//    }
//    
//    @inline(__always) private func op_1c() -> Int {
//        handleAbsoluteIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_1d() -> Int {
//        handleAbsoluteIndexedXRead(ora)
//    }
//    
//    @inline(__always) private func op_1e() -> Int {
//        handleAbsoluteIndexedXModify(asl)
//    }
//    
//    @inline(__always) private func op_1f() -> Int {
//        handleAbsoluteIndexedXModify(slo)
//    }
//    
//    @inline(__always) private func op_21() -> Int {
//        handleIndexedIndirectXRead(and)
//    }
//    
//    @inline(__always) private func op_22() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_23() -> Int {
//        handleIndexedIndirectXModify(rla)
//    }
//    
//    @inline(__always) private func op_25() -> Int {
//        handleZeroPageRead(and)
//    }
//    
//    @inline(__always) private func op_26() -> Int {
//        handleZeroPageModify(rol)
//    }
//    
//    @inline(__always) private func op_27() -> Int {
//        handleZeroPageModify(rla)
//    }
//    
//    @inline(__always) private func op_28() -> Int {
//        plp()
//    }
//    
//    @inline(__always) private func op_2a() -> Int {
//        handleAccumulatorModify(rol)
//    }
//    
//    @inline(__always) private func op_2b() -> Int {
//        handleImmediateRead(anc)
//    }
//    
//    @inline(__always) private func op_2c() -> Int {
//        handleAbsoluteRead(bit)
//    }
//    
//    @inline(__always) private func op_2d() -> Int {
//        handleAbsoluteRead(and)
//    }
//    
//    @inline(__always) private func op_2e() -> Int {
//        handleAbsoluteModify(rol)
//    }
//    
//    @inline(__always) private func op_2f() -> Int {
//        handleAbsoluteModify(rla)
//    }
//    
//    @inline(__always) private func op_31() -> Int {
//        handleIndirectIndexedYRead(and)
//    }
//    
//    @inline(__always) private func op_32() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_33() -> Int {
//        handleIndirectIndexedYModify(rla)
//    }
//    
//    @inline(__always) private func op_34() -> Int {
//        handleZeroPageIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_35() -> Int {
//        handleZeroPageIndexedXRead(and)
//    }
//    
//    @inline(__always) private func op_36() -> Int {
//        handleZeroPageIndexedXModify(rol)
//    }
//    
//    @inline(__always) private func op_37() -> Int {
//        handleZeroPageIndexedXModify(rla)
//    }
//    
//    @inline(__always) private func op_38() -> Int {
//        handleImplied(sec)
//    }
//    
//    @inline(__always) private func op_39() -> Int {
//        handleAbsoluteIndexedYRead(and)
//    }
//    
//    @inline(__always) private func op_3a() -> Int {
//        handleImplied(nop)
//    }
//    
//    @inline(__always) private func op_3b() -> Int {
//        handleAbsoluteIndexedYModify(rla)
//    }
//    
//    @inline(__always) private func op_3c() -> Int {
//        handleAbsoluteIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_3d() -> Int {
//        handleAbsoluteIndexedXRead(and)
//    }
//    
//    @inline(__always) private func op_3e() -> Int {
//        handleAbsoluteIndexedXModify(rol)
//    }
//    
//    @inline(__always) private func op_3f() -> Int {
//        handleAbsoluteIndexedXModify(rla)
//    }
//    
//    @inline(__always) private func op_40() -> Int {
//        rti()
//    }
//    
//    @inline(__always) private func op_41() -> Int {
//        handleIndexedIndirectXRead(eor)
//    }
//    
//    @inline(__always) private func op_42() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_43() -> Int {
//        handleIndexedIndirectXModify(sre)
//    }
//    
//    @inline(__always) private func op_44() -> Int {
//        handleZeroPageRead(nopRead)
//    }
//    
//    @inline(__always) private func op_45() -> Int {
//        handleZeroPageRead(eor)
//    }
//    
//    @inline(__always) private func op_46() -> Int {
//        handleZeroPageModify(lsr)
//    }
//    
//    @inline(__always) private func op_47() -> Int {
//        handleZeroPageModify(sre)
//    }
//    
//    @inline(__always) private func op_48() -> Int {
//        pha()
//    }
//    
//    @inline(__always) private func op_49() -> Int {
//        handleImmediateRead(eor)
//    }
//    
//    @inline(__always) private func op_4b() -> Int {
//        handleImmediateRead(alr)
//    }
//    
//    @inline(__always) private func op_4d() -> Int {
//        handleAbsoluteRead(eor)
//    }
//    
//    @inline(__always) private func op_4e() -> Int {
//        handleAbsoluteModify(lsr)
//    }
//    
//    @inline(__always) private func op_4f() -> Int {
//        handleAbsoluteModify(sre)
//    }
//    
//    @inline(__always) private func op_50() -> Int {
//        branch()
//    }
//    
//    @inline(__always) private func op_51() -> Int {
//        handleIndirectIndexedYRead(eor)
//    }
//    
//    @inline(__always) private func op_52() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_53() -> Int {
//        handleIndirectIndexedYModify(sre)
//    }
//    
//    @inline(__always) private func op_54() -> Int {
//        handleZeroPageIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_55() -> Int {
//        handleZeroPageIndexedXRead(eor)
//    }
//    
//    @inline(__always) private func op_56() -> Int {
//        handleZeroPageIndexedXModify(lsr)
//    }
//    
//    @inline(__always) private func op_57() -> Int {
//        handleZeroPageIndexedXModify(sre)
//    }
//    
//    @inline(__always) private func op_58() -> Int {
//        handleImplied(cli)
//    }
//    
//    @inline(__always) private func op_59() -> Int {
//        handleAbsoluteIndexedYRead(eor)
//    }
//    
//    @inline(__always) private func op_5a() -> Int {
//        handleImplied(nop)
//    }
//    
//    @inline(__always) private func op_5b() -> Int {
//        handleAbsoluteIndexedYModify(sre)
//    }
//    
//    @inline(__always) private func op_5c() -> Int {
//        handleAbsoluteIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_5d() -> Int {
//        handleAbsoluteIndexedXRead(eor)
//    }
//    
//    @inline(__always) private func op_5e() -> Int {
//        handleAbsoluteIndexedXModify(lsr)
//
//    }
//    
//    @inline(__always) private func op_5f() -> Int {
//        handleAbsoluteIndexedXModify(sre)
//    }
//    
//    @inline(__always) private func op_61() -> Int {
//        handleIndexedIndirectXRead(adc)
//    }
//    
//    @inline(__always) private func op_62() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_63() -> Int {
//        handleIndexedIndirectXModify(rra)
//    }
//    
//    @inline(__always) private func op_64() -> Int {
//        handleZeroPageRead(nopRead)
//    }
//    
//    @inline(__always) private func op_65() -> Int {
//        handleZeroPageRead(adc)
//    }
//    
//    @inline(__always) private func op_66() -> Int {
//        handleZeroPageModify(ror)
//    }
//    
//    @inline(__always) private func op_67() -> Int {
//        handleZeroPageModify(rra)
//    }
//    
//    @inline(__always) private func op_68() -> Int {
//        pla()
//    }
//    
//    @inline(__always) private func op_69() -> Int {
//        handleImmediateRead(adc)
//    }
//    
//    @inline(__always) private func op_6a() -> Int {
//        handleAccumulatorModify(ror)
//    }
//    
//    @inline(__always) private func op_6b() -> Int {
//        handleImmediateRead(arr)
//    }
//    
//    @inline(__always) private func op_6c() -> Int {
//        jmpIndirect()
//    }
//    
//    @inline(__always) private func op_6d() -> Int {
//        handleAbsoluteRead(adc)
//    }
//    
//    @inline(__always) private func op_6e() -> Int {
//        handleAbsoluteModify(ror)
//    }
//    
//    @inline(__always) private func op_6f() -> Int {
//        handleAbsoluteModify(rra)
//    }
//    
//    @inline(__always) private func op_70() -> Int {
//        branch()
//    }
//    
//    @inline(__always) private func op_71() -> Int {
//        handleIndirectIndexedYRead(adc)
//    }
//    
//    @inline(__always) private func op_72() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_73() -> Int {
//        handleIndirectIndexedYModify(rra)
//    }
//    
//    @inline(__always) private func op_74() -> Int {
//        handleZeroPageIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_75() -> Int {
//        handleZeroPageIndexedXRead(adc)
//    }
//    
//    @inline(__always) private func op_76() -> Int {
//        handleZeroPageIndexedXModify(ror)
//    }
//    
//    @inline(__always) private func op_77() -> Int {
//        handleZeroPageIndexedXModify(rra)
//    }
//    
//    @inline(__always) private func op_78() -> Int {
//        handleImplied(sei)
//    }
//    
//    @inline(__always) private func op_79() -> Int {
//        handleAbsoluteIndexedYRead(adc)
//    }
//    
//    @inline(__always) private func op_7a() -> Int {
//        handleImplied(nop)
//    }
//    
//    @inline(__always) private func op_7b() -> Int {
//        handleAbsoluteIndexedYModify(rra)
//    }
//    
//    @inline(__always) private func op_7c() -> Int {
//        handleAbsoluteIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_7d() -> Int {
//        handleAbsoluteIndexedXRead(adc)
//    }
//    
//    @inline(__always) private func op_7e() -> Int {
//        handleAbsoluteIndexedXModify(ror)
//    }
//    
//    @inline(__always) private func op_7f() -> Int {
//        handleAbsoluteIndexedXModify(rra)
//    }
//    
//    @inline(__always) private func op_80() -> Int {
//        handleImmediateRead(nopRead)
//    }
//    
//    @inline(__always) private func op_81() -> Int {
//        handleIndexedIndirectXWrite(sta)
//    }
//    
//    @inline(__always) private func op_82() -> Int {
//        handleImmediateRead(nopRead(_:))
//    }
//    
//    @inline(__always) private func op_83() -> Int {
//        handleIndexedIndirectXWrite(sax)
//    }
//    
//    @inline(__always) private func op_84() -> Int {
//        handleZeroPageWrite(sty)
//    }
//    
//    @inline(__always) private func op_86() -> Int {
//        handleZeroPageWrite(stx)
//    }
//    
//    @inline(__always) private func op_87() -> Int {
//        handleZeroPageWrite(sax)
//    }
//    
//    @inline(__always) private func op_89() -> Int {
//        handleImmediateRead(nopRead)
//    }
//    
//    @inline(__always) private func op_8a() -> Int {
//        handleImplied(txa)
//    }
//    
//    @inline(__always) private func op_8b() -> Int {
//        handleImmediateRead(xaa)
//    }
//    
//    @inline(__always) private func op_8c() -> Int {
//        handleAbsoluteWrite(sty)
//    }
//    
//    @inline(__always) private func op_8e() -> Int {
//        handleAbsoluteWrite(stx)
//    }
//    
//    @inline(__always) private func op_8f() -> Int {
//        handleAbsoluteWrite(sax)
//    }
//    
//    @inline(__always) private func op_90() -> Int {
//        branch()
//    }
//    
//    @inline(__always) private func op_91() -> Int {
//        handleIndirectIndexedYWrite(sta)
//    }
//    
//    @inline(__always) private func op_92() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_93() -> Int {
//        handleIndirectIndexedYWrite(ahx)
//    }
//    
//    @inline(__always) private func op_94() -> Int {
//        handleZeroPageIndexedXWrite(sty)
//    }
//    
//    @inline(__always) private func op_95() -> Int {
//        handleZeroPageIndexedXWrite(sta)
//    }
//    
//    @inline(__always) private func op_96() -> Int {
//        handleZeroPageIndexedYWrite(stx)
//    }
//    
//    @inline(__always) private func op_97() -> Int {
//        handleZeroPageIndexedYWrite(sax)
//    }
//    
//    @inline(__always) private func op_98() -> Int {
//        handleImplied(tya)
//    }
//    
//    @inline(__always) private func op_99() -> Int {
//        handleAbsoluteIndexedYWrite(sta)
//    }
//    
//    @inline(__always) private func op_9a() -> Int {
//        handleImplied(txs)
//    }
//    
//    @inline(__always) private func op_9b() -> Int {
//        handleAbsoluteIndexedYWrite(tas)
//    }
//    
//    @inline(__always) private func op_9c() -> Int {
//        handleAbsoluteIndexedXWrite(shy)
//    }
//    
//    @inline(__always) private func op_9e() -> Int {
//        handleAbsoluteIndexedYWrite(shx)
//    }
//    
//    @inline(__always) private func op_9f() -> Int {
//        handleAbsoluteIndexedYWrite(ahx)
//    }
//    
//    @inline(__always) private func op_a0() -> Int {
//        handleImmediateRead(ldy)
//    }
//    
//    @inline(__always) private func op_a1() -> Int {
//        handleIndexedIndirectXRead(lda)
//    }
//    
//    @inline(__always) private func op_a2() -> Int {
//        handleImmediateRead(ldx)
//    }
//    
//    @inline(__always) private func op_a3() -> Int {
//        handleIndexedIndirectXRead(lax)
//    }
//    
//    @inline(__always) private func op_a4() -> Int {
//        handleZeroPageRead(ldy)
//    }
//    
//    @inline(__always) private func op_a6() -> Int {
//        handleZeroPageRead(ldx)
//    }
//    
//    @inline(__always) private func op_a7() -> Int {
//        handleZeroPageRead(lax)
//    }
//    
//    @inline(__always) private func op_aa() -> Int {
//        handleImplied(tax)
//    }
//    
//    @inline(__always) private func op_ab() -> Int {
//        handleImmediateRead(lax)
//    }
//    
//    @inline(__always) private func op_ac() -> Int {
//        handleAbsoluteRead(ldy)
//    }
//    
//    @inline(__always) private func op_ae() -> Int {
//        handleAbsoluteRead(ldx)
//
//    }
//    
//    @inline(__always) private func op_af() -> Int {
//        handleAbsoluteRead(lax)
//    }
//    
//    @inline(__always) private func op_b2() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_b3() -> Int {
//        handleIndirectIndexedYRead(lax)
//    }
//    
//    @inline(__always) private func op_b4() -> Int {
//        handleZeroPageIndexedXRead(ldy)
//    }
//    
//    @inline(__always) private func op_b6() -> Int {
//        handleZeroPageIndexedYRead(ldx)
//    }
//    
//    @inline(__always) private func op_b7() -> Int {
//        handleZeroPageIndexedYRead(lax)
//    }
//    
//    @inline(__always) private func op_b8() -> Int {
//        handleImplied(clv)
//    }
//    
//    @inline(__always) private func op_b9() -> Int {
//        handleAbsoluteIndexedYRead(lda)
//    }
//    
//    @inline(__always) private func op_ba() -> Int {
//        handleImplied(tsx)
//    }
//    
//    @inline(__always) private func op_bb() -> Int {
//        handleAbsoluteIndexedYRead(las)
//    }
//    
//    @inline(__always) private func op_bc() -> Int {
//        handleAbsoluteIndexedXRead(ldy)
//    }
//    
//    @inline(__always) private func op_be() -> Int {
//        handleAbsoluteIndexedYRead(ldx)
//    }
//    
//    @inline(__always) private func op_bf() -> Int {
//        handleAbsoluteIndexedYRead(lax)
//    }
//    
//    @inline(__always) private func op_c0() -> Int {
//        handleImmediateRead(cpy)
//    }
//    
//    @inline(__always) private func op_c1() -> Int {
//        handleIndexedIndirectXRead(cmp)
//    }
//    
//    @inline(__always) private func op_c2() -> Int {
//        handleImmediateRead(nopRead)
//    }
//    
//    @inline(__always) private func op_c3() -> Int {
//        handleIndexedIndirectXModify(dcp)
//    }
//    
//    @inline(__always) private func op_c4() -> Int {
//        handleZeroPageRead(cpy)
//    }
//    
//    @inline(__always) private func op_c5() -> Int {
//        handleZeroPageRead(cmp)
//    }
//    
//    @inline(__always) private func op_c6() -> Int {
//        handleZeroPageModify(dec)
//    }
//    
//    @inline(__always) private func op_c7() -> Int {
//        handleZeroPageModify(dcp)
//    }
//    
//    @inline(__always) private func op_ca() -> Int {
//        handleImplied(dex)
//    }
//    
//    @inline(__always) private func op_cb() -> Int {
//        handleImmediateRead(axs)
//    }
//    
//    @inline(__always) private func op_cc() -> Int {
//        handleAbsoluteRead(cpy)
//    }
//    
//    @inline(__always) private func op_cd() -> Int {
//        handleAbsoluteRead(cmp)
//    }
//    
//    @inline(__always) private func op_ce() -> Int {
//        handleAbsoluteModify(dec)
//    }
//    
//    @inline(__always) private func op_cf() -> Int {
//        handleAbsoluteModify(dcp)
//    }
//    
//    @inline(__always) private func op_d1() -> Int {
//        handleIndirectIndexedYRead(cmp)
//    }
//    
//    @inline(__always) private func op_d2() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_d3() -> Int {
//        handleIndirectIndexedYModify(dcp)
//    }
//    
//    @inline(__always) private func op_d4() -> Int {
//        handleZeroPageIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_d5() -> Int {
//        handleZeroPageIndexedXRead(cmp)
//    }
//    
//    @inline(__always) private func op_d6() -> Int {
//        handleZeroPageIndexedXModify(dec)
//    }
//    
//    @inline(__always) private func op_d7() -> Int {
//        handleZeroPageIndexedXModify(dcp)
//    }
//    
//    @inline(__always) private func op_d8() -> Int {
//        handleImplied(cld)
//    }
//    
//    @inline(__always) private func op_d9() -> Int {
//        handleAbsoluteIndexedYRead(cmp)
//    }
//    
//    @inline(__always) private func op_da() -> Int {
//        handleImplied(nop)
//    }
//    
//    @inline(__always) private func op_db() -> Int {
//        handleAbsoluteIndexedYModify(dcp)
//    }
//    
//    @inline(__always) private func op_dc() -> Int {
//        handleAbsoluteIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_dd() -> Int {
//        handleAbsoluteIndexedXRead(cmp)
//    }
//    
//    @inline(__always) private func op_de() -> Int {
//        handleAbsoluteIndexedXModify(dec)
//    }
//    
//    @inline(__always) private func op_df() -> Int {
//        handleAbsoluteIndexedXModify(dcp)
//    }
//    
//    @inline(__always) private func op_e0() -> Int {
//        handleImmediateRead(cpx)
//    }
//    
//    @inline(__always) private func op_e1() -> Int {
//        handleIndexedIndirectXRead(sbc)
//    }
//    
//    @inline(__always) private func op_e2() -> Int {
//        handleImmediateRead(nopRead)
//    }
//    
//    @inline(__always) private func op_e3() -> Int {
//        handleIndexedIndirectXModify(isc)
//    }
//    
//    @inline(__always) private func op_e4() -> Int {
//        handleZeroPageRead(cpx)
//    }
//    
//    @inline(__always) private func op_e5() -> Int {
//        handleZeroPageRead(sbc)
//    }
//    
//    @inline(__always) private func op_e7() -> Int {
//        handleZeroPageModify(isc)
//    }
//    
//    @inline(__always) private func op_e9() -> Int {
//        handleImmediateRead(sbc)
//    }
//    
//    @inline(__always) private func op_ea() -> Int {
//        handleImplied(nop)
//    }
//    
//    @inline(__always) private func op_eb() -> Int {
//        handleImmediateRead(sbc)
//    }
//    
//    @inline(__always) private func op_ec() -> Int {
//        handleAbsoluteRead(cpx)
//    }
//    
//    @inline(__always) private func op_ed() -> Int {
//        handleAbsoluteRead(sbc)
//    }
//    
//    @inline(__always) private func op_ee() -> Int {
//        handleAbsoluteModify(inc)
//    }
//    
//    @inline(__always) private func op_ef() -> Int {
//        handleAbsoluteModify(isc)
//    }
//    
//    @inline(__always) private func op_f1() -> Int {
//        handleIndirectIndexedYRead(sbc)
//    }
//    
//    @inline(__always) private func op_f2() throws(XemuError) -> Int {
//        throw .emulatorHalted
//    }
//    
//    @inline(__always) private func op_f3() -> Int {
//        handleIndirectIndexedYModify(isc)
//    }
//    
//    @inline(__always) private func op_f4() -> Int {
//        handleZeroPageIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_f5() -> Int {
//        handleZeroPageIndexedXRead(sbc)
//    }
//    
//    @inline(__always) private func op_f6() -> Int {
//        handleZeroPageIndexedXModify(inc)
//    }
//    
//    @inline(__always) private func op_f7() -> Int {
//        handleZeroPageIndexedXModify(isc)
//    }
//    
//    @inline(__always) private func op_f8() -> Int {
//        handleImplied(sed)
//    }
//    
//    @inline(__always) private func op_f9() -> Int {
//        handleAbsoluteIndexedYRead(sbc)
//    }
//    
//    @inline(__always) private func op_fa() -> Int {
//        handleImplied(nop)
//    }
//    
//    @inline(__always) private func op_fb() -> Int {
//        handleAbsoluteIndexedYModify(isc)
//    }
//    
//    @inline(__always) private func op_fc() -> Int {
//        handleAbsoluteIndexedXRead(nopRead)
//    }
//    
//    @inline(__always) private func op_fd() -> Int {
//        handleAbsoluteIndexedXRead(sbc)
//    }
//    
//    @inline(__always) private func op_fe() -> Int {
//        handleAbsoluteIndexedXModify(inc)
//    }
//    
//    @inline(__always) private func op_ff() -> Int {
//        handleAbsoluteIndexedXModify(isc)
//    }
//    
//    enum CodingKeys: String, CodingKey {
//        case registers
//        case state
//    }
//}
//
//extension MOS6502Fast {
//    public func getRegisters() -> [RegisterInfo] {
//        [
//            .regular("A", size: 1, value: .u8(registers.a)),
//            .regular("X", size: 1, value: .u8(registers.x)),
//            .regular("Y", size: 1, value: .u8(registers.y)),
//            .stack("S", size: 1, value: .u8(registers.s)),
//            .programCounter("PC", size: 2, value: .u16(registers.pc)),
//            .flags(
//                "P",
//                size: 1,
//                flags: [
//                    .init(mask: UInt(Flags.CARRY_MASK), acronym: "C", name: "Carry"),
//                    .init(mask: UInt(Flags.ZERO_MASK), acronym: "Z", name: "Zero"),
//                    .init(mask: UInt(Flags.INTERRUPT_DISABLED_MASK), acronym: "I", name: "Interrupt"),
//                    .init(mask: UInt(Flags.DECIMAL_MASK), acronym: "D", name: "Decimal"),
//                    .init(mask: 0b0001_0000, acronym: "B", name: "Break"),
//                    .init(mask: 0b0010_0000, acronym: "1", name: "Always"),
//                    .init(mask: UInt(Flags.OVERFLOW_MASK), acronym: "V", name: "Overflow"),
//                    .init(mask: UInt(Flags.NEGATIVE_MASK), acronym: "N", name: "Negative"),
//                ],
//                value: .u8(registers.p.value())
//            )
//        ]
//    }
//    
//    public func setRegister(name: String, value: u64) {
//        switch name.uppercased() {
//            case "A":
//                registers.a = u8(value & 0xff)
//            case "X":
//                registers.x = u8(value & 0xff)
//            case "Y":
//                registers.y = u8(value & 0xff)
//            case "S":
//                registers.s = u8(value & 0xff)
//            case "PC":
//                registers.pc = u16(value & 0xffff)
//            case "P":
//                registers.p = .init(u8(value & 0xff))
//            default:
//                print("Unknown register: \(name) = \(value)")
//        }
//    }
//}
