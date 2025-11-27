import SwiftUI
import XemuCore
import XemuNES
import stylx

enum SaveSelection: Hashable {
    case new
    case existing(UUID)
}

struct GameSaveListItem: View {
    @Environment(\.modelContext) var modelContext

    @State private var name: String
    @State private var renameOpen: Bool = false
    @State private var deleteOpen: Bool = false
    @State private var thumbnail: Image? = nil
    
    let save: GameSave
    
    init(save: GameSave) {
        self.save = save
        self._name = State(initialValue: save.name)
    }

    var body: some View {
        HStack(spacing: .m) {
            if let thumbnail {
                thumbnail
                    .resizable()
                    .frame(height: 96)
                    .aspectRatio(256 / 240, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: .xxs))
            }
            
            VStack(spacing: .xs) {
                Text(save.name)
                    .retroTextStyle(size: .m)
                    .foregroundStyle(.foregroundDefault)
            }
            
            if save.game.currentSave == save.id {
                Spacer()

                Image(systemName: "checkmark")
                    .foregroundStyle(.roleForeground)
                    .environment(\.colorRole, .success)
            }
        }
        .onAppear {
            if let data = save.screenshot, let thumbnail = generateThumbnail(with: data) {
                self.thumbnail = thumbnail
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .contextMenu {
            Text(verbatim: save.name)
            
            RenameButton()
            
            Button("Duplicate", systemImage: "document.on.clipboard.fill") {
                let save = GameSave(game: save.game, data: save.data, screenshot: save.screenshot)
                save.name = "Copy of \(self.save.name)"
                save.game.saves.append(save)
            }
            
//            ShareLink(items: [game.data])
            
            if ClipboardService.canUseClipboard {
                Button("Copy as Base64", systemImage: "clipboard") {
                    ClipboardService.shared.copy(save.data.base64EncodedString())
                }
            }
            
            Divider()

            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteOpen = true
            }
        }
        .renameAction {
            renameOpen = true
        }
        .alert("Rename Save", isPresented: $renameOpen) {
            TextField("Name", text: $name)
            
            Button("Cancel", role: .cancel) {
                renameOpen = false
            }
            
            Button("Rename") {
                save.name = name
                renameOpen = false
            }
        }
        .alert(
            "Are you sure you want to delete this save data?",
            isPresented: $deleteOpen,
            actions: {
                Button("Cancel", role: .cancel) {
                    deleteOpen = false
                }
                
                Button("Delete", role: .destructive) {
                    deleteOpen = false
                    
                    if save.game.currentSave == save.id {
                        save.game.currentSave = nil
                    }
                    
                    modelContext.delete(save)
                }
            },
            message: {
                Text("All save data will be lost forever, make sure you have a backup before deleting important files.")
            }
        )
    }
    
    private func generateThumbnail(with data: Data) -> Image? {
        guard let colorSpace = Palette.default.colorSpace,
              let provider = CGDataProvider(data: data as CFData) else {
            return nil
        }
        
        let image = CGImage(
            width: 256, // TODO: encode this in the save / image data
            height: 240,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: 256,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
        
        return Image(platformImage: PlatformImage(cgImage: image, size: CGSize(width: 256, height: 240)))
    }
}

struct GameSaveListView: View {
    @Environment(\.dismiss) var dismiss
    
    let game: Game
    let hasBattery: Bool

    @Binding var selection: SaveSelection?
    
    init(game: Game) {
        self.game = game
        
        do {
            let iNes = try iNesFile(game.data)
            hasBattery = iNes.hasBattery ||
                (iNes.prgPersistentRamSize ?? 0) > 0 ||
                (iNes.chrPersistentRamSize ?? 0) > 0
        } catch {
            hasBattery = false
        }
        
        self._selection = Binding(
            get: {
                if let currentSave = game.currentSave {
                    .existing(currentSave)
                } else {
                    .new
                }
            },
            set: {
                guard let selection = $0 else {
                   return
                }
                
                switch selection {
                    case .new:
                        game.currentSave = nil
                    case .existing(let id):
                        game.currentSave = id
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                if hasBattery {
                    HStack(spacing: .m) {
                        RoundedRectangle(cornerRadius: .xxs)
                            .stroke(
                                .roleForeground,
                                style: StrokeStyle(
                                    lineWidth: 4,
                                    lineCap: .round,
                                    dash: [4, 8]
                                )
                            )
                            .frame(width: 256 * 96 / 240, height: 96)
                            .environment(\.colorRole, .primary)
                        
                        VStack(spacing: .xs) {
                            Text("New Save")
                                .retroTextStyle(size: .m)
                                .foregroundStyle(.foregroundDefault)
                        }
                        
                        if game.currentSave == nil {
                            Spacer()
                            
                            Image(systemName: "checkmark")
                                .foregroundStyle(.roleForeground)
                                .environment(\.colorRole, .success)
                        }
                    }
                    .tag(SaveSelection.new)
                }
                
                ForEach(game.saves) { save in
                    GameSaveListItem(save: save)
                        .tag(SaveSelection.existing(save.id))
                }
            }
#if canImport(UIKit)
            .environment(\.editMode, .constant(.active))
#endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: .xxxs) {
                        Text("Manage Saves")
                            .foregroundStyle(.foregroundDefault)
                        Text(game.name)
                            .foregroundStyle(.foregroundMuted)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Done")
                            .foregroundStyle(.roleForeground)
                            .environment(\.colorRole, .primary)
                    })
                }
            }
            .overlay {
                if !hasBattery {
                    ContentUnavailableView(label: {
                        Image(systemName: "minus.plus.batteryblock.slash")
                            .font(.system(size: .xxxl))
                        Text("No Battery")
                            .textStyle(.subtitle)
                            .padding(.s)
                    }, description: {
                        Text("This cartridge has no persistent memory. Save data is not available.")
                            .textStyle(.body(.l, .regular))
                    })
                }
            }
        }
    }
}
