extension UInt16 {
    public func p16(endianess: Endianess = .little) -> [UInt8] {
        let b0 = UInt8(self & 0xFF)
        let b1 = UInt8(self >> 8  )
        
        return switch endianess {
            case .little:
                [b0, b1]
            case .big:
                [b1, b0]
        }
    }
}
   
extension UInt32 {
    public func p32(endianess: Endianess = .little) -> [UInt8] {
        let b0 = UInt8(self       & 0xFF)
        let b1 = UInt8(self >> 8  & 0xFF)
        let b2 = UInt8(self >> 16 & 0xFF)
        let b3 = UInt8(self >> 24       )
        
        return switch endianess {
            case .little:
                [b0, b1, b2, b3]
            case .big:
                [b3, b2, b1, b0]
        }
    }
}

extension UInt64 {
    public func p64(endianess: Endianess = .little) -> [UInt8] {
        let b0 = UInt8(self       & 0xFF)
        let b1 = UInt8(self >> 8  & 0xFF)
        let b2 = UInt8(self >> 16 & 0xFF)
        let b3 = UInt8(self >> 24 & 0xFF)
        let b4 = UInt8(self >> 32 & 0xFF)
        let b5 = UInt8(self >> 40 & 0xFF)
        let b6 = UInt8(self >> 48 & 0xFF)
        let b7 = UInt8(self >> 56       )

        return switch endianess {
            case .little:
                [b0, b1, b2, b3, b4, b5, b6, b7]
            case .big:
                [b7, b6, b5, b4, b3, b2, b1, b0]
        }
    }
}
   
extension [UInt8] {
    public func u16(endianess: Endianess = .little) -> UInt16 {
        switch endianess {
            case .little:
                UInt16(self[0]) << 8 | UInt16(self[1])
            case .big:
                UInt16(self[1]) << 8 | UInt16(self[0])
        }
    }
    
    public func u32(endianess: Endianess = .little) -> UInt32 {
        switch endianess {
            case .little:
                UInt32(self[0]) << 24 | UInt32(self[1]) << 16 | UInt32(self[2]) << 8 | UInt32(self[3])
            case .big:
                UInt32(self[3]) << 24 | UInt32(self[2]) << 16 | UInt32(self[1]) << 8 | UInt32(self[0])
        }
    }
    
    public func u64(endianess: Endianess = .little) -> UInt64 {
        switch endianess {
            case .little:
                UInt64(self[0]) << 56 | UInt64(self[1]) << 48 | UInt64(self[2]) << 40 | UInt64(self[3]) << 32 | UInt64(self[4]) << 24 | UInt64(self[5]) << 16 | UInt64(self[6]) << 8 | UInt64(self[7])
            case .big:
                UInt64(self[7]) << 56 | UInt64(self[6]) << 48 | UInt64(self[5]) << 40 | UInt64(self[4]) << 32 | UInt64(self[3]) << 24 | UInt64(self[2]) << 16 | UInt64(self[1]) << 8 | UInt64(self[0])
        }
    }
}
