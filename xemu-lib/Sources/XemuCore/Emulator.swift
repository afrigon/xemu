import Foundation
import CoreGraphics
import XemuFoundation

public protocol Emulator: Codable {
    var frame: [u8]? { get }
    var frameWidth: Int { get }
    var frameHeight: Int { get }

    func load(program: Data, saveData: Data?) throws(XemuError)
    func reset()
    func clock() throws(XemuError)
}

extension Emulator {
    public var frameAspectRatio: Double {
        Double(frameWidth) / Double(frameHeight)
    }
}
