import XemuFoundation

public enum MapperType: u16, Codable {
    case nrom = 0
    case mmc1 = 1
    case unrom = 2
    case cnrom = 3
    case axrom = 7
    case cprom = 13
    case gxrom = 66
}
