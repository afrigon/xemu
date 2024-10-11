import stylx
import SwiftUI

extension ColorRole {
    static let primary: ColorRole = {
        let emphasis = Color(hex: 0x93E1D8)
        let emphasisDark = Color(hex: 0xA5382A)
        let muted = Color(hex: 0xDDFFF7)
        let mutedDark = Color(hex: 0xA15B52)
        
        return .init(
            emphasis: .init(light: emphasis, dark: emphasisDark),
            muted: .init(light: muted, dark: mutedDark)
        )
    }()
    
    static let secondary: ColorRole = {
        let emphasis = Color(hex: 0xAA4465)
        let emphasisDark = Color(hex: 0x57BCAA)
        let muted = Color(hex: 0xFFA69E)
        let mutedDark = Color(hex: 0x5F837C)
        
        return .init(
            emphasis: .init(light: emphasis, dark: emphasisDark),
            muted: .init(light: muted, dark: mutedDark)
        )
    }()
    
    static let tertiary: ColorRole = {
        let emphasis = Color(hex: 0x462255)
        let emphasisDark = Color(hex: 0x57BCAA)
        let muted = Color(hex: 0xB497C1)
        let mutedDark = Color(hex: 0x5F837C)
        
        return .init(
            emphasis: .init(light: emphasis, dark: emphasisDark),
            muted: .init(light: muted, dark: mutedDark)
        )
    }()
}

#Preview("Primary") {
    ColorRoleView()
        .environment(\.colorRole, .primary)
}

#Preview("Secondary") {
    ColorRoleView()
        .environment(\.colorRole, .secondary)
}

#Preview("Tertiary") {
    ColorRoleView()
        .environment(\.colorRole, .tertiary)
}
