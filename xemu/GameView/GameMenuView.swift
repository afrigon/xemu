import SwiftUI
import XemuCore

struct GameMenuView: View {
    @Environment(AppContext.self) var context
    
    @Binding var isRunning: Bool
    @State var settingsOpen: Bool = false
    
    let name: String
    let emulator: Emulator?
    
    var body: some View {
        List {
            Section(content: {
                createButton(text: "Resume", icon: "play") {
                    isRunning = true
                }
            }, header: {
                Text(name)
                    .lineLimit(2)
                    .retroTextStyle(size: .m, weight: .bold)
                    .foregroundStyle(.foregroundDefault)
                    .padding(.vertical, .xs)
            })
            
            Section {
                createButton(text: "Reset", icon: "arrow.clockwise") {
                    emulator?.reset()
                    isRunning = true
                }
                
                createButton(text: "Power Cycle", icon: "power") {
                    emulator?.powerCycle()
                    isRunning = true
                }
            }
            
            Section {
                createButton(text: "Save State", icon: "square.and.arrow.down") {
                    
                }
                
                createButton(text: "Load State", icon: "square.and.arrow.up") {
                }
            }
            
            Section {
                createButton(text: "Settings", icon: "gear") {
                    settingsOpen = true
                }
                
                createButton(text: "Return to Game Library", icon: "arrowshape.turn.up.backward") {
                    context.set(state: .menu)
                }
            }
        }
        .sheet(isPresented: $settingsOpen) {
            SettingsView()
        }
    }
    
    @ViewBuilder
    func createButton(
        text: LocalizedStringResource,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: { action() },
            label: {
                Label(title: {
                    Text(text)
                        .retroTextStyle(size: .m, weight: .bold)
                        .lineLimit(2)
                }, icon: {
                    Image(systemName: icon)
                        .font(.system(size: .m, weight: .bold))
                })
            }
        )
    }
}

#Preview {
    GameMenuView(
        isRunning: .constant(true),
        name: "The Legend of Zelda",
        emulator: nil
    )
    .mockContext()
}
