import XemuFoundation

protocol BusComponent {
    func read(at address: u16) -> u8
    func write(_ data: u8, at address: u16)
}

protocol BusDelegate: AnyObject {
    func bus(bus: Bus, didSendReadSignalAt address: u16) -> u8
    func bus(bus: Bus, didSendWriteSignalAt address: u16, _ data: u8)
}

class Bus {
    weak var delegate: BusDelegate!
    
    public func read(at address: u16) -> u8 {
        delegate.bus(bus: self, didSendReadSignalAt: address)
    }
    
    public func write(_ data: u8, at address: u16) {
        delegate.bus(bus: self, didSendWriteSignalAt: address, data)
    }
    
    public func read16(at address: u16) -> u16 {
        let lo = u16(self.read(at: address))
        let hi = u16(self.read(at: address + 1))

        return hi << 8 | lo
    }

    public func write16(_ data: u16, at address: u16) {
        let data = data.p16(endianess: .little)
        
        self.write(data[0], at: address)
        self.write(data[1], at: address + 1)
    }

    public func read16Glitched(at address: u16) -> u16 {
        
        // 6502 hardware bug, instead of reading from 0xC0FF/0xC100 it reads from 0xC0FF/0xC000
        if address & 0xFF == 0xFF {
            let lo = u16(self.read(at: address))
            let hi = u16(self.read(at: address & 0xFF00))
            
            return hi << 8 | lo
        }

        return self.read16(at: address)
    }
}
