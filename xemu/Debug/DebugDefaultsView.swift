import SwiftUI
import XemuCore
import stylx
import SwiftData

struct DebugDefaultsView: View {
    @Environment(AppContext.self) private var context
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Button("Clear Database", role: .destructive) {
                do {
                    try modelContext.container.erase()
                } catch {
                    print(error)
                }
            }
        }
        .title("Debug Settings", displayMode: .inline)
    }
}

#Preview {
    DebugDefaultsView()
}
