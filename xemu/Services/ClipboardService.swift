#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

import UniformTypeIdentifiers

class ClipboardService {
    enum ContentType {
        case image
        case data
        case url
        case string
        
        var pasteboardType: String {
            switch self {
                case .image: return UTType.image.identifier
                case .data: return UTType.data.identifier
                case .url: return UTType.url.identifier
                case .string: return UTType.text.identifier
            }
        }
    }
    
    static var shared = ClipboardService()
    
    static var canUseClipboard: Bool {
#if os(iOS) || os(visionOS) || targetEnvironment(macCatalyst) || os(macOS)
        true
#else
        false
#endif
    }
    
    func copy(_ value: String) {
#if os(iOS) || os(visionOS) || targetEnvironment(macCatalyst)
        UIPasteboard.general.string = value
#elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
#endif
    }
    
    func contains(_ type: ContentType) -> Bool {
#if os(iOS) || os(visionOS) || targetEnvironment(macCatalyst)
        UIPasteboard.general.contains(pasteboardTypes: [type.pasteboardType])
#elseif os(macOS)
        guard let items = NSPasteboard.general.pasteboardItems else {
            return false
        }
        
        for item in items {
            if item.types.contains(where: { t in
                t.rawValue == type.pasteboardType
            }) {
                return true
            }
        }
        
        return false
#else
        return false
#endif
    }
}
