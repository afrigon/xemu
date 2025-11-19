import XemuFoundation

protocol BusDelegate: AnyObject {
    func setNMI(_ value: Bool)
    func setIRQ(_ value: Bool)

    func stepPPU(until cycle: Int)
    func stepAPU()
    
    func getDmcReadAddress() -> u16

    func bus(bus: Bus, didSendReadSignalAt address: u16) -> u8?
    func bus(bus: Bus, didSendDebugReadSignalAt address: u16) -> u8?
    func bus(bus: Bus, didSendWriteSignalAt address: u16, _ data: u8)
    
    func bus(bus: Bus, didSendReadVideoSignalAt address: u16) -> u8?
    func bus(bus: Bus, didSendWriteVideoSignalAt address: u16, _ data: u8)
}

final class Bus {
    var openBus: u8 = 0x00
    var openVideoBus: u8 = 0x00

    weak var delegate: BusDelegate!
    
    func setNMI(_ value: Bool) {
        delegate.setNMI(value)
    }
    
    func setIRQ(_ value: Bool) {
        delegate.setIRQ(value)
    }
    
    @discardableResult
    public func read(at address: u16) -> u8 {
        guard let data = delegate.bus(bus: self, didSendReadSignalAt: address) else {
            return openBus
        }
        
        openBus = data
        return data
    }
    
    @discardableResult
    public func debugRead(at address: u16) -> u8 {
        guard let data = delegate.bus(bus: self, didSendDebugReadSignalAt: address) else {
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
    
    public func stepPPU(until cycle: Int) {
        delegate.stepPPU(until: cycle)
    }
    
    public func stepAPU() {
        delegate.stepAPU()
    }
    
    public func getDmcReadAddress() -> u16 {
        delegate.getDmcReadAddress()
    }
}
