import Foundation
import XemuFoundation

public protocol Emulator: Codable {
    func load(program: Data, saveData: Data?) throws(XemuError)
    func reset()
    func clock() throws(XemuError)
}
