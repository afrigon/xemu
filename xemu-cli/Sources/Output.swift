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

struct Output {
    static let shared = Output()
    
    var currentSize = OutputSize()
    
    mutating func startMonitoring() {
//        signal(SIGWINCH) { [unowned self] _ in
//            currentSize = Output.getOutputSize()
//        }
        
        currentSize = Output.getOutputSize()
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
