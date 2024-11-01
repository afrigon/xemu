import XemuFoundation

struct Sweep: Codable {
    enum Index: Codable {
        case square1
        case square2
    }
    
    var enabled: Bool = false
    var negate: Bool = false
    var reload: Bool = false
    var period: u8 = 0
    var divider: u8 = 0
    var shift: u8 = 0
    var index: Index
    
    init(_ index: Index) {
        self.index = index
    }
    
    func targetPeriod(_ period: u16) -> u16 {
        let changeAmount = period >> shift
        
        guard negate else {
            return period + changeAmount
        }
        
        switch index {
            case .square1:
                if shift == 0 || period == 0 {
                    return 0
                }
                
                return period - changeAmount - 1
            case .square2:
                return period - changeAmount
        }
    }
}
