import Foundation
import XemuFoundation

final class Memory: Codable {
    var data: [u8]
    
    init(count: Int) {
        self.data = .init(repeating: 0, count: count)
    }

    init(_ data: [u8]) {
        self.data = data
    }
    
    init(_ data: Data) {
        self.data = [u8](data)
    }
    
    func read(at address: u16) -> u8 {
        data[address]
    }
    
    func write(_ value: u8, at address: u16) {
        data[address] = value
    }

    func mirroredRead(at address: u16) -> u8 {
        let count = data.count
        
        guard count > 0 else {
            return 0
        }
        
        return data[address % u16(data.count)]
    }
    
    func mirroredWrite(_ value: u8, at address: u16) {
        let count = data.count
        
        guard count > 0 else {
            return
        }
        
        data[address % u16(count)] = value
    }
    
    func bankedRead(at address: u16, bankIndex: Int, bankSize: Int) -> u8 {
        let address = (bankSize * bankIndex) + (Int(address) % bankSize)
        return data[address % data.count]
    }
    
    func bankedWrite(_ value: u8, at address: u16, bankIndex: Int, bankSize: Int) {
        let address = (bankSize * bankIndex) + (Int(address) % bankSize)
        data[address % data.count] = value
    }
}
