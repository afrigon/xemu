import SwiftUI
import XemuCore
import XemuFoundation
import stylx

struct MenuView: View {
    @Environment(AppContext.self) private var context
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    #if !os(tvOS)
    @AppStorage("tabview.customization.menu")
    var customization: TabViewCustomization
    #endif

    @State private var settingsOpen: Bool = false
    @State private var importOpen: Bool = false
    @State private var selection: SystemType = .nes
    
    private func createTab(system: SystemType) -> some TabContent<SystemType> {
        Tab(value: system, content: {
            GameBoxCollectionView(system: system, importOpen: $importOpen)
        }, label: {
            createTabViewLabel(system: system)
        })
        .customizationID("app.frigon.xemu.\(system.rawValue)")
    }
    
    var body: some View {
        NavigationStack() {
            createContent()
                .toolbarTitleDisplayMode(.inline)
                .scrollEdgeEffectStyle(.soft, for: .top)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gear") {
                            settingsOpen = true
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add Game", systemImage: "plus") {
                            importOpen = true
                        }
                        .disabled(importOpen)
                    }
                    
                    ToolbarItem(placement: .title) {
                        Label(title: {
                            Text(selection.title)
                                .retroTextStyle(size: .l)
                        }, icon: {
                            Image(selection.icon)
                                .resizable()
                                .frame(width: .init(.l, tvOS: .xxxl), height: .init(.l, tvOS: .xxxl))
                        })
                        .padding(.horizontal, .m)
                        .padding(.vertical, 10)
                        .labelStyle(.titleAndIcon)
                        .glassEffect(.regular)
                    }
                }
        }
        .sheet(isPresented: $settingsOpen) {
            SettingsView()
        }
        .gameImporter(
            isPresented: $importOpen,
            onCompletion: { result in
                switch result {
                    case .success(let urls):
                        for url in urls {
                            do throws(XemuError) {
                                let game = try ImportExportService.shared.importGame(url)
                                modelContext.insert(game)
                            } catch let error {
                                context.error = error
                            }
                        }
                    case .failure:
                        context.error = .importError
                }
            }
        )
        .environment(\.error, ErrorAction(handler: { error in
            context.error = error
            return .handled
        }))
    }
    
    @ViewBuilder
    private func createContent() -> some View {
        createSystemContent(system: .nes)
        
        // TODO: edit this to allow multi system layout
    }
    
    @ViewBuilder
    private func createSystemContent(system: SystemType) -> some View {
        if system.active {
            GameBoxCollectionView(system: system, importOpen: $importOpen)
        }
    }
    
    @ViewBuilder
    private func createTabViewContent() -> some View {
        TabView(selection: $selection) {
            if SystemType.nes.active {
                Tab(value: .nes, content: {
                    GameBoxCollectionView(system: .nes, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .nes)
                })
                .customizationID(SystemType.nes.customizationIdentifier)
            }
            
            if SystemType.superNes.active {
                Tab(value: .superNes, content: {
                    GameBoxCollectionView(system: .superNes, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .superNes)
                })
                .customizationID(SystemType.superNes.customizationIdentifier)
            }
            
            if SystemType.gameBoy.active {
                Tab(value: .gameBoy, content: {
                    GameBoxCollectionView(system: .gameBoy, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .gameBoy)
                })
                .customizationID(SystemType.gameBoy.customizationIdentifier)
            }
            
            if SystemType.gameBoyColor.active {
                Tab(value: .gameBoyColor, content: {
                    GameBoxCollectionView(system: .gameBoyColor, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .gameBoyColor)
                })
                .customizationID(SystemType.gameBoyColor.customizationIdentifier)
            }
            
            if SystemType.gameBoyAdvance.active {
                Tab(value: .gameBoyAdvance, content: {
                    GameBoxCollectionView(system: .gameBoyAdvance, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .gameBoyAdvance)
                })
                .customizationID(SystemType.gameBoyAdvance.customizationIdentifier)
            }
            
            if SystemType.nintendo64.active {
                Tab(value: .nintendo64, content: {
                    GameBoxCollectionView(system: .nintendo64, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .nintendo64)
                })
                .customizationID(SystemType.nintendo64.customizationIdentifier)
            }
            
            if SystemType.DS.active {
                Tab(value: .DS, content: {
                    GameBoxCollectionView(system: .DS, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .DS)
                })
                .customizationID(SystemType.DS.customizationIdentifier)
            }
            
            if SystemType.gamecube.active {
                Tab(value: .gamecube, content: {
                    GameBoxCollectionView(system: .gamecube, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .gamecube)
                })
                .customizationID(SystemType.gamecube.customizationIdentifier)
            }
            
            if SystemType.dreamcast.active {
                Tab(value: .dreamcast, content: {
                    GameBoxCollectionView(system: .dreamcast, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .dreamcast)
                })
                .customizationID(SystemType.dreamcast.customizationIdentifier)
            }
            
            if SystemType.segaGenesis.active {
                Tab(value: .segaGenesis, content: {
                    GameBoxCollectionView(system: .segaGenesis, importOpen: $importOpen)
                }, label: {
                    createTabViewLabel(system: .segaGenesis)
                })
                .customizationID(SystemType.segaGenesis.customizationIdentifier)
            }
        }
#if !os(tvOS)
        .tabViewCustomization($customization)
#endif
        .tabViewStyle(.sidebarAdaptable)
    }
    
    @ViewBuilder
    private func createTabViewLabel(system: SystemType) -> some View {
#if canImport(UIKit)
        if sizeClass == .regular {
            Label(title: {
                Text(system.title)
            }, icon: {
                system.smallIcon
            })
        } else {
            Text(system.title)
        }
#elseif canImport(AppKit)
        Text(system.title)
#endif
    }
}

#Preview {
    MenuView()
        .mockContext()
}
