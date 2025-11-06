import Foundation
import CoreGraphics
import XemuFoundation

public protocol Emulator: Codable {
    var frequency: Int { get }
    var frameWidth: Int { get }
    var frameHeight: Int { get }
    
    var frameBuffer: [u8]? { get }
    var audioBuffer: [f32]? { get }

    func load(program: Data, saveData: Data?) throws(XemuError)
    func reset()
    func clock() throws(XemuError)
}

extension Emulator {
    public var frameAspectRatio: Double {
        Double(frameWidth) / Double(frameHeight)
    }
}
