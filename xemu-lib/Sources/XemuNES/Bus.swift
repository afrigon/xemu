import XemuFoundation

protocol BusDelegate: AnyObject {
    func requestNMI()
    func requestIRQ()
    
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
    var openVideoBus: u8 = 0x00

    weak var delegate: BusDelegate!
    
    func requestNMI() {
        delegate.requestNMI()
    }
    
    func requestIRQ() {
        delegate.requestIRQ()
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
    public func ppuRead(at address: u16) -> u8 {
        guard let data = delegate.bus(bus: self, didSendReadVideoSignalAt: address) else {
            return openVideoBus
        }

        openVideoBus = data
        return data
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
}
