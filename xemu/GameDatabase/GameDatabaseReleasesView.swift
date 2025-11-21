import SwiftUI
import XemuCore
import XemuFoundation
import stylx
import XKit

struct GameDatabaseReleasesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppContext.self) var context

    private var game: Game
    
    @State private var items: [OpenVGDBRelease] = []
    @State private var search: String
    @State private var isLoading: Bool = false

    init(game: Game) {
        self.game = game
        search = game.name.sanitizedFilename
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.artworkURL) { item in
                    Button(action: {
                        loadArtwork(at: item.artworkURL)
                    }, label: {
                        HStack(spacing: .xs) {
                            ImageView(
                                .remote(item.artworkURL),
                                content: { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .xxxxxl, maxHeight: .xxxxxl)
                                },
                                placeholder: {
                                    RoundedRectangle(cornerRadius: .xxs)
                                        .fill(.backgroundMuted)
                                        .frame(width: .xxxxxl, height: .xxxxxl)
                                }
                            )
                            
                            Text(item.name)
                                .lineLimit(2)
                                .foregroundStyle(.foregroundDefault)
                                .retroTextStyle(size: .l)
                        }
                    })
                }
            }
            .overlay {
                if items.isEmpty {
                    VStack {
                        Text("No releases found")
                            .retroTextStyle(size: .xl, weight: .bold)
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .background(.backgroundMuted)
                        .padding(.xl)
                }
            }
            .title("Change Artwork", displayMode: .inline)
#if canImport(UIKit)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
#else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
#endif
        }
        .task {
            searchReleases()
        }
        .onChange(of: search) { _, _ in
            searchReleases()
        }
        .searchable(text: $search, prompt: "Search Games")
        .searchPresentationToolbarBehavior(.avoidHidingContent)
    }
    
    private func loadArtwork(at url: URL) {
        isLoading = true
        
        Task {
            guard let artwork = try? await Request(url).data() else {
                isLoading = false
                return
            }

            game.artwork = artwork.body
            dismiss()
        }
    }
    
    private func searchReleases() {
        guard let service = OpenVGDBService.shared, let openVGDBIdentifier = game.system.openVGDBIdentifier else {
            return
        }
        
        do throws(XemuError) {
            items = try service.getReleases(
                like: search,
                for: openVGDBIdentifier
            )
        } catch let error {
            context.error = error
        }
    }
}

#Preview {
    GameDatabaseReleasesView(
        game: Game(
            identifier: .init("0"),
            name: "Zelda",
            data: .init(),
            system: .nes
        )
    )
}
