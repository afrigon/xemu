import SwiftUI
import XemuCore
import stylx

struct DebugDefaultsView: View {
    @Environment(AppContext.self) private var context
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Button("Clear Database", role: .destructive) {
                try? modelContext.delete(model: Game.self)
            }
        }
        .title("Debug Settings", displayMode: .inline)
    }
}

#Preview {
    DebugDefaultsView()
}
