import Foundation
import XemuFoundation

public protocol Emulator: Codable {
    var frame: Data? { get }
    
    func load(program: Data, saveData: Data?) throws(XemuError)
    func reset()
    func clock() throws(XemuError)
}
