import SwiftUI
import XemuCore
import stylx

struct ReadyView: View {
    @State var isPresentingSettings: Bool = false
    @State var selection: String = ConsoleType.nes.rawValue
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                createGameBoxCollectionView(for: .nes)
                    .tag(ConsoleType.nes.rawValue)
                
                createGameBoxCollectionView(for: .snes)
                    .tag(ConsoleType.snes.rawValue)
                
                createGameBoxCollectionView(for: .gb)
                    .tag(ConsoleType.gb.rawValue)
                
                createGameBoxCollectionView(for: .gbc)
                    .tag(ConsoleType.gbc.rawValue)
                
                createGameBoxCollectionView(for: .gba)
                    .tag(ConsoleType.gba.rawValue)
                
                createGameBoxCollectionView(for: .n64)
                    .tag(ConsoleType.n64.rawValue)
                
                createGameBoxCollectionView(for: .ds)
                    .tag(ConsoleType.ds.rawValue)
                
                createGameBoxCollectionView(for: .gc)
                    .tag(ConsoleType.gc.rawValue)
                
                createGameBoxCollectionView(for: .wii)
                    .tag(ConsoleType.wii.rawValue)
                
                createGameBoxCollectionView(for: .dc)
                    .tag(ConsoleType.dc.rawValue)
                
                createGameBoxCollectionView(for: .gen)
                    .tag(ConsoleType.gen.rawValue)
            }
#if os(iOS)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gear") {
                        isPresentingSettings.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
        }
        .environment(\.colorRole, .primary)
    }
    
    @ViewBuilder
    private func createGameBoxCollectionView(for console: ConsoleType) -> some View {
        if console.active {
            GameBoxCollectionView(console: console)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Label(title: {
                            Text(console.title)
                                .textStyle(.code(.s))
                        }, icon: {
                            Image(console.icon)
                                .resizable()
                                .frame(width: .l, height: .l)
                        })
                        .labelStyle(.titleAndIcon)
                    }
                }
        }
    }
}

#Preview {
    ReadyView()
}
