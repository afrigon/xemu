protocol BusComponent {
    func read(at address: UInt16) -> UInt8
    func write(_ data: UInt8, at address: UInt16)
}

protocol BusDelegate: AnyObject {
    func bus(bus: Bus, didSendReadSignalAt address: UInt16) -> UInt8
    func bus(bus: Bus, didSendWriteSignalAt address: UInt16, _ data: UInt8)
}

class Bus {
    weak var delegate: BusDelegate!
    
    public func read(at address: UInt16) -> UInt8 {
        delegate.bus(bus: self, didSendReadSignalAt: address)
    }
    
    public func write(_ data: UInt8, at address: UInt16) {
        delegate.bus(bus: self, didSendWriteSignalAt: address, data)
    }
}
