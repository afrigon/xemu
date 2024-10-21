import Foundation
import XemuFoundation

public protocol Emulator {
    
    @MainActor
    func load(program: Data) throws(XemuError)
    
    @MainActor
    func clock() throws(XemuError)
}
