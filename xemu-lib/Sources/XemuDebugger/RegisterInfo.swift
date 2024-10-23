import Foundation
import XemuFoundation

public enum RegisterInfo: Identifiable {
    case regular(RegularRegister)
    case stack(RegularRegister)
    case programCounter(RegularRegister)
    case flags(FlagRegister)
    
    public var id: String {
        switch self {
            case .regular(let r):
                r.id
            case .stack(let r):
                r.id
            case .programCounter(let r):
                r.id
            case .flags(let r):
                r.id
        }
    }
    
    public static func regular(_ name: String, size: Int, value: RegisterValue) -> RegisterInfo {
        .regular(RegularRegister(name: name, size: size, value: value))
    }
    
    public static func stack(_ name: String, size: Int, value: RegisterValue) -> RegisterInfo {
        .stack(RegularRegister(name: name, size: size, value: value))
    }
    
    public static func programCounter(_ name: String, size: Int, value: RegisterValue) -> RegisterInfo {
        .programCounter(RegularRegister(name: name, size: size, value: value))
    }

    public static func flags(_ name: String, size: Int, flags: [RegisterFlag], value: RegisterValue) -> RegisterInfo {
        .flags(FlagRegister(name: name, size: size, flags: flags, value: value))
    }
}

public struct RegularRegister: Identifiable {
    public let name: String
    public let size: Int
    public let value: RegisterValue
    
    public var id: String {
        name
    }

    public init(name: String, size: Int, value: RegisterValue) {
        self.name = name
        self.size = size
        self.value = value
    }
}

public enum RegisterValue {
    case u8(u8)
    case u16(u16)
    case u32(u32)
    case u64(u64)
    
    public var int: Int {
        switch self {
            case .u8(let value):
                Int(value)
            case .u16(let value):
                Int(value)
            case .u32(let value):
                Int(value)
            case .u64(let value):
                Int(value)
        }
    }

    public var uint: UInt {
        switch self {
            case .u8(let value):
                UInt(value)
            case .u16(let value):
                UInt(value)
            case .u32(let value):
                UInt(value)
            case .u64(let value):
                UInt(value)
        }
    }
}

public struct FlagRegister: Identifiable {
    public let name: String
    public let size: Int
    public let flags: [RegisterFlag]
    public let value: RegisterValue
    
    public var id: String {
        name
    }
    
    public init(
        name: String,
        size: Int,
        flags: [RegisterFlag],
        value: RegisterValue
    ) {
        self.name = name
        self.size = size
        self.flags = flags
        self.value = value
    }
}

public struct RegisterFlag {
    public let mask: UInt
    public let acronym: String
    public let name: String
    
    public init(mask: UInt, acronym: String, name: String) {
        self.mask = mask
        self.acronym = acronym
        self.name = name
    }
    
    public var displayName: String {
        if name.isEmpty {
            acronym
        } else {
            name
        }
    }
}
