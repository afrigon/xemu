public class MockSystem: BusDelegate {
    let cpu: Chip6502
    let bus: Bus = .init()
    var ram: [UInt8] = .init(repeating: 0, count: 0xFFFF)

    init() {
        cpu = .init(bus: bus)
        bus.delegate = self
    }
    
    func bus(bus: Bus, didSendReadSignalAt address: UInt16) -> UInt8 {
        ram[address]
    }
    
    func bus(bus: Bus, didSendWriteSignalAt address: UInt16, _ data: UInt8) {
        ram[address] = data
    }
}
