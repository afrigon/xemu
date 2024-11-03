import XemuFoundation

struct InfoCommand: Command {
    static let configuration = CommandConfiguration(
        name: "info",
        description: "Lists information about the argument, or lists what possible arguments are if none are provided."
    )
    
    let argument: String?
    
    init() {
        argument = nil
    }
    
    init(arguments: [String]) {
        argument = arguments.first
    }
    
    func run(context: AppContext) throws(XemuError) {
        if let argument {
            switch argument {
                case "stack", "s":
                    try StackCommand().run(context: context)
                case "registers", "reg", "r":
                    try RegisterCommand().run(context: context)
                case "break", "b":
                    Output.shared.print("List of info subcommands:")
                    Output.shared.print("")
                    Output.shared.print("info [b]reak -- Status of breakpoints")
                    Output.shared.print("info [r]egister -- List of registers and their content")
                    Output.shared.print("info [s]tack -- Backtrace of the stack")
                default:
                    throw .unknownCommand
            }
        } else {
            Output.shared.print("List of info subcommands:")
            Output.shared.print("")
            Output.shared.print("info [b]reak -- Status of breakpoints")
            Output.shared.print("info [r]egister -- List of registers and their content")
            Output.shared.print("info [s]tack -- Backtrace of the stack")
        }
    }
}

