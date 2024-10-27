import XemuFoundation

protocol BusDelegate: AnyObject {
    func nmiSignal() -> Bool
    func irqSignal() -> Bool
    
    func bus(bus: Bus, didSendReadSignalAt address: u16) -> u8?
    func bus(bus: Bus, didSendWriteSignalAt address: u16, _ data: u8)
    
    func bus(bus: Bus, didSendReadVideoSignalAt address: u16) -> u8?
    func bus(bus: Bus, didSendWriteVideoSignalAt address: u16, _ data: u8)

    func bus(bus: Bus, didSendReadZeroPageSignalAt address: u8) -> u8
    func bus(bus: Bus, didSendWriteZeroPageSignalAt address: u8, _ data: u8)
    
    func bus(bus: Bus, didSendReadStackSignalAt address: u8) -> u8
    func bus(bus: Bus, didSendWriteStackSignalAt address: u8, _ data: u8)
}

class Bus {
    var openBus: u8 = 0x00
    
    weak var delegate: BusDelegate!
    
    public func nmiSignal() -> Bool {
        delegate.nmiSignal()
    }
    
    public func irqSignal() -> Bool {
        delegate.irqSignal()
    }

    @discardableResult
    public func read(at address: u16) -> u8 {
        guard let data = delegate.bus(bus: self, didSendReadSignalAt: address) else {
            return openBus
        }
        
        openBus = data
        return data
    }
    
    public func write(_ data: u8, at address: u16) {
        delegate.bus(bus: self, didSendWriteSignalAt: address, data)
    }
    
    @discardableResult
    public func ppuRead(at address: u16) -> u8? {
        return delegate.bus(bus: self, didSendReadVideoSignalAt: address)
    }
    
    public func ppuWrite(_ data: u8, at address: u16) {
        delegate.bus(bus: self, didSendWriteVideoSignalAt: address, data)
    }

    @discardableResult
    public func readZeroPage(at address: u8) -> u8 {
        return delegate.bus(bus: self, didSendReadZeroPageSignalAt: address)
    }
    
    public func writeZeroPage(_ data: u8, at address: u8) {
        delegate.bus(bus: self, didSendWriteZeroPageSignalAt: address, data)
    }
    
    @discardableResult
    public func readStack(at address: u8) -> u8 {
        return delegate.bus(bus: self, didSendReadStackSignalAt: address)
    }
    
    public func writeStack(_ data: u8, at address: u8) {
        delegate.bus(bus: self, didSendWriteStackSignalAt: address, data)
    }

    public func readString(at address: u16) -> String {
        var result: String = ""
        var i: u16 = 0
        
        while true {
            let data = read(at: address &+ i)
            
            if data == 0x00 {
                break
            }
            
            result += String(UnicodeScalar(data))
            i &+= 1
        }
        
        return result
    }
}
