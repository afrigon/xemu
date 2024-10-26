import XemuFoundation
import XemuDebugger

struct BreakCommand: Command {
    static var configuration = CommandConfiguration(
        name: "breakpoints",
        description: "Creates a breakpoint at the given address."
    )
    
    let address: u64?
    
    init() {
        address = nil
    }

    init(arguments: [String]) {
        if let address = arguments.first {
            self.address = u64(address, radix: 16) ?? u64(address)
        } else {
            self.address = nil
        }
    }
    
    func run(context: XemuCLI) throws(XemuError) {
        guard let address else {
            Output.shared.print("Please provide an address. example: break 0x1234")
            return
        }
        
        let breakpoint = Breakpoint(
            id: context.breakpoints.last?.id ?? 0,
            address: address
        )
        
        context.breakpoints.append(breakpoint)
    }
}

