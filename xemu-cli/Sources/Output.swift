import Darwin
import Dispatch
import Prism

struct OutputSize {
    let width: Int
    let height: Int
    
    init(width: Int = 80, height: Int = 40) {
        self.width = width
        self.height = height
    }
}

@MainActor
var CURRENT_OUTPUT_SIZE = OutputSize()

class Output {
    
    @MainActor
    static var shared = Output()
    
    @MainActor
    func startMonitoring() {
        signal(SIGWINCH) { _ in
            CURRENT_OUTPUT_SIZE = Output.getOutputSize()
        }
        
        CURRENT_OUTPUT_SIZE = Output.getOutputSize()
    }
    
    @MainActor
    func getCurrentSize() -> OutputSize {
        CURRENT_OUTPUT_SIZE
    }
    
    private static func getOutputSize() -> OutputSize {
        var w = winsize()
        
        return if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            OutputSize(width: Int(w.ws_col), height: Int(w.ws_row))
        } else {
            OutputSize(width: 80, height: 40)
        }
    }

    func print(_ message: Any) {
        Swift.print(message)
    }
    
    func prism(@ElementBuilder _ elements: () -> [PrismElement]) {
        Swift.print(Prism(spacing: .custom, elements: elements()))
    }
}
