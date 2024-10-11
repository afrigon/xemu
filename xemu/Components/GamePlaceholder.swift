import SwiftUI
import XemuCore

struct GamePlaceholder: View {
    private let console: ConsoleType
    
    init(console: ConsoleType) {
        self.console = console
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: .xxs)
            .fill(.backgroundMuted)
            .overlay {
                Image(console.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.m)
                    .opacity(0.75)
            }
    }
}

#Preview {
    VStack {
        ForEach(ConsoleType.allCases, id: \.rawValue) { console in
            GamePlaceholder(console: .nes)
                .frame(width: 100, height: 100)
        }
    }
}
