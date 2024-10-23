import Foundation

public class BitIterator {
    private var data: Data
    private var bitCursor: Int = 0
    
    public init(data: Data) {
        self.data = data
    }
    
    public var index: Int {
        bitCursor / 8
    }
    
    public func advanceBit(by amount: Int) {
        bitCursor += amount
    }
    
    public func advanceByte(by amount: Int) {
        bitCursor += amount * 8
    }

    public func takeBit(_ n: Int) throws(XemuError) -> UInt {
        guard bitCursor + n < data.count * 8 else {
            throw .indexOutOfBounds
        }
        
        var result: UInt = 0
        
        for i in 0..<n {
            let byteOffset = bitCursor / 8
            let bitOffset = bitCursor % 8
            let byte = data[byteOffset]
            
            let bit = (byte >> (7 - bitOffset)) & 1
            result |= (UInt(bit) << (n - i - 1))
            
            advanceBit(by: 1)
        }
        
        return result
    }
    
    public func takeByte() throws(XemuError) -> u8 {
        guard let byte = try takeByte(1).first else {
            throw .indexOutOfBounds
        }
        
        return byte
    }

    public func takeByte(_ n: Int) throws(XemuError) -> [u8] {
        guard index + n < data.count else {
            throw .indexOutOfBounds
        }
        
        guard bitCursor % 8 == 0 else {
            throw .dataOutOfAlignment
        }
        
        defer { advanceByte(by: n) }
        return .init(data.subdata(in: index..<index+n))
    }
}
