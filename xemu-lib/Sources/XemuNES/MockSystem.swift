import Foundation
import XemuFoundation
import XemuCore
import XemuDebugger
import XemuAsm

public class MockSystem: Emulator, BusDelegate {
    let cpu: MOS6502
    let bus: Bus = .init()
    var ram: [u8] = .init(repeating: 0, count: 0xFFFF)
//    var cartridge: Cartridge?

    public init() {
        cpu = .init(bus: bus)
        bus.delegate = self
    }
    
    func bus(bus: Bus, didSendReadSignalAt address: u16) -> u8 {
        guard address < ram.count else {
            return 0
        }
        
        return ram[address]
    }
    
    func bus(bus: Bus, didSendWriteSignalAt address: u16, _ data: u8) {
        guard address < ram.count else {
            return
        }
        
        ram[address] = data
    }
    
    public func load(program: Data) throws(XemuError) {
        let file = try iNesFile(program)
        
        file.pgrRom.copyBytes(to: &ram[0x8000], count: file.pgrRom.count)
        file.pgrRom.copyBytes(to: &ram[0x8000 + file.pgrRom.count], count: file.pgrRom.count)
        
        cpu.registers.pc = bus.read16(at: MOS6502.InterruptType.reset.address)
        cpu.registers.pc = 0xc000 // TODO: remove this
    }
    
    public func clock() throws(XemuError) {
        _ = try cpu.clock()
    }
}

extension MockSystem: Debuggable {
    public var arch: Arch {
        .mos6502
    }
    
    public func getRegisters() -> [RegisterInfo] {
        cpu.getRegisters()
    }
    
    public func setRegister(name: String, value: u64) {
        cpu.setRegister(name: name, value: value)
    }
    
    public func getMemory() -> [u8] {
        ram
    }
    
    public func setMemory(address: Int, value: u8) {
        ram[address] = value
    }

    public func stepi() throws(XemuError) {
        // run the first cycle
        try clock()
        
        // finish the instruction
        while cpu.state.tick >= 1 && cpu.state.tick < 10 {
            try clock()
        }
    }
}
