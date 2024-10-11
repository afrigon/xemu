import SwiftUI
import XemuPersistance
import XemuCore
import stylx
import XKit

struct GameDatabaseReleasesView: View {
    @Environment(\.dismiss) var dismiss
    
    private var game: Game
    
    @State private var items: [OpenVGDBRelease] = []
    @State private var search: String
    @State private var isLoading: Bool = false

    init(game: Game) {
        self.game = game
        search = game.name
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
                                        .frame(maxWidth: 100, maxHeight: 100)
                                },
                                placeholder: {
                                    RoundedRectangle(cornerRadius: .xxs)
                                        .fill(.backgroundMuted)
                                        .frame(width: 100, height: 100)
                                }
                            )
                            
                            Text(item.name)
                                .lineLimit(2)
                                .foregroundStyle(.foregroundDefault)
                                .textStyle(.code(.l))
                        }
                    })
                }
            }
            .overlay {
                if items.isEmpty {
                    VStack {
                        Text("No releases found")
                            .textStyle(.code(.l))
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
            .navigationTitle("Change Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
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
        guard let service = OpenVGDBService.shared else {
            return
        }
        
        items = service.getReleases(like: search, for: game.console.openVGDBIdentifier)
    }
}

#Preview {
    GameDatabaseReleasesView(
        game: Game(
            identifier: .init("0"),
            name: "Zelda",
            data: .init(),
            console: .nes
        )
    )
}
