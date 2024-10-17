import SwiftUI
import stylx

struct SettingsView: View {
    @AppStorage(.gameCollectionSorting) private var gameCollectionSorting: GameCollectionSorting = .lastPlayed
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Controllers") {
                    Picker("Active Controller", selection: .constant("test")) {
                        ForEach(GameControllerService.shared.controllers, id: \.self) {
                            Text($0.vendorName ?? "")
                        }
                    }
                }
                
                Section("Game Collection") {
                    Picker("Sort By", selection: $gameCollectionSorting) {
                        Text("Last Played")
                            .tag(GameCollectionSorting.lastPlayed)
                        Text("Game Title")
                            .tag(GameCollectionSorting.name)
                    }
                }
            }
            .title("Settings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .padding(.init(.zero, macOS: .s))
        }
    }
}

#Preview {
    SettingsView()
}
