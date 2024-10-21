import SwiftUI
import XemuNES
import XemuDebugger

public struct NesDebugView: View {
    @State var registers: [RegisterInfo] = []
    
    let nes: MockSystem = .init()
    
    public init() {
    }
    
    public var body: some View {
        VStack {
            ForEach(registers) { register in
                switch register {
                    case .regular(let r):
                        createRegularRegister(r)
                    case .stack(let r):
                        createRegularRegister(r)
                    case .programCounter(let r):
                        createRegularRegister(r)
                    case .flags(let r):
                        createFlagRegister(r)
                }
            }
        }
        
        Button("get") {
            self.registers = nes.getCPU().getRegisters()
        }
    }
    
    private func createRegularRegister(_ register: RegularRegister) -> some View {
        Text(verbatim: "\(register.name): \(register.value.hex(prefix: "$"))")
    }
             
    private func createFlagRegister(_ register: FlagRegister) -> some View {
        Text(verbatim: "\(register.name): \(register)")
    }
}
