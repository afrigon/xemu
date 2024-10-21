import Foundation
import XemuFoundation

public protocol RomFile {
    
    @MainActor
    static var fileExtensions: [String] { get }
    
    @MainActor
    static var magic: [UInt8] { get }
    
    @MainActor
    init(_ data: Data) throws(XemuError)
}

extension RomFile {
    
    @MainActor
    public static func supportFileExtension(_ value: String) -> Bool {
        let value = if value.contains("."), let last = value.split(separator: ".").last {
            String(last)
        } else {
            value
        }
        
        return fileExtensions
            .map { $0.lowercased() }
            .contains(value.lowercased())
    }
    
    @MainActor
    public static func supportFileExtension(_ value: URL) -> Bool {
        supportFileExtension(value.pathExtension)
    }
    
    @MainActor
    public static func hasMagic(_ data: Data) -> Bool {
        data.withUnsafeBytes {
            guard $0.count >= magic.count else {
                return false
            }
            
            guard let data = $0.bindMemory(to: UInt8.self).baseAddress else {
                return false
            }
            
            for i in 0..<magic.count {
                if data[i] != magic[i] {
                    return false
                }
            }
            
            return true
        }
    }
}
