import Foundation
import XemuCore
import XemuFoundation

public class NES: Emulator, BusDelegate {
    var cycles: UInt = 0
    
    let cpu: MOS6502
    let apu: APU
    let ppu: PPU
    
    let bus: Bus = Bus()
    var cartridge: Cartridge? = nil
    
    let wram: Memory
    let vram: Memory
    
    enum CodingKeys: CodingKey {
        case cpu
        case apu
        case ppu
        case wram
        case vram
    }

    @MainActor
    public init() {
        cpu = .init(bus: bus)
        apu = .init(bus: bus)
        ppu = .init(bus: bus)
        wram = .init(.init(repeating: 0, count: 0x800))
        vram = .init(.init(repeating: 0, count: 0x800))
        bus.delegate = self
        
        reset()
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cpu = try container.decode(MOS6502.self, forKey: .cpu)
        apu = try container.decode(APU.self, forKey: .apu)
        ppu = try container.decode(PPU.self, forKey: .ppu)
        wram = try container.decode(Memory.self, forKey: .wram)
        vram = try container.decode(Memory.self, forKey: .vram)

        bus.delegate = self
        cpu.bus = bus
        apu.bus = bus
        ppu.bus = bus
    }
    
    func nmiSignal() -> Bool {
        Bool(ppu.control & ppu.status & 0b1000_0000)
    }
    
    func irqSignal() -> Bool {
        guard !cpu.registers.p.interruptDisabled else {
            return false
        }
        
        return false
    }
    
    func bus(bus: Bus, didSendReadSignalAt address: u16) -> u8? {
        if address == 0x4015 {
            
        }
        
        let mappedData = cartridge?.cpuRead(at: address) ?? bus.openBus
        
        switch address {
            case 0x0000..<0x2000:
                return wram.mirroredRead(at: address)
            case 0x6000...0xFFFF:
                return mappedData
            default:
                return bus.openBus
        }
    }
    
    func bus(bus: Bus, didSendWriteSignalAt address: u16, _ data: u8) {
        cartridge?.cpuWrite(data, at: address)
        
        switch address {
            case 0x0000..<0x2000:
                return wram.mirroredWrite(data, at: address)
            default:
                break
        }
    }
    
    func bus(bus: Bus, didSendReadZeroPageSignalAt address: u8) -> u8 {
        wram.data[Int(address)]
    }
    
    func bus(bus: Bus, didSendWriteZeroPageSignalAt address: u8, _ data: u8) {
        wram.data[Int(address)] = data
    }
    
    func bus(bus: Bus, didSendReadStackSignalAt address: u8) -> u8 {
        wram.data[Int(address) + 0x100]
    }
    
    func bus(bus: Bus, didSendWriteStackSignalAt address: u8, _ data: u8) {
        wram.data[Int(address) + 0x100] = data
    }

    public func load(program: Data, saveData: Data? = nil) throws(XemuError) {
        let iNes = try iNesFile(program)
        cartridge = Cartridge(from: iNes, saveData: saveData)
    }
    
    public func reset() {
        cycles = 0
        cpu.state.tick = 0
        cpu.state.servicing = .reset
    }
    
    public func clock() throws(XemuError) {
        try cpu.clock()
        
        apu.clock()
        
        ppu.clock()
        ppu.clock()
        ppu.clock()
        
        cycles &+= 1
    }
}
