import Foundation
import XemuFoundation

public protocol RomFile {
    
    static var fileExtensions: [String] { get }
    
    static var magic: [u8] { get }
    
    init(_ data: Data) throws(XemuError)
}

extension RomFile {
    
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
    
    public static func supportFileExtension(_ value: URL) -> Bool {
        supportFileExtension(value.pathExtension)
    }
    
    public static func hasMagic(_ data: Data) -> Bool {
        data.withUnsafeBytes {
            guard $0.count >= magic.count else {
                return false
            }
            
            guard let data = $0.bindMemory(to: u8.self).baseAddress else {
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
