import SwiftUI
import XemuPersistance

struct DebugDefaultsView: View {
    @Environment(AppContext.self) private var context
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Button("Clear Database", role: .destructive) {
                try? modelContext.delete(model: Game.self)
            }
        }
        .navigationTitle(Text("Debug Settings"))
    }
}

#Preview {
    DebugDefaultsView()
}
