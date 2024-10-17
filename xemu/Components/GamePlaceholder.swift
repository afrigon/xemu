import SwiftUI
import XemuCore

struct GamePlaceholder: View {
    private let system: SystemType
    
    init(system: SystemType) {
        self.system = system
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: .xxs)
            .fill(.backgroundEmphasis)
            .overlay {
                Image(system.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.l)
                    .opacity(0.75)
            }
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [
            .init(.fixed(100)),
            .init(.fixed(100)),
            .init(.fixed(100))
        ]) {
            ForEach(SystemType.allCases, id: \.rawValue) { system in
                GamePlaceholder(system: system)
                    .frame(width: 100, height: 100)
            }
        }
    }
}
