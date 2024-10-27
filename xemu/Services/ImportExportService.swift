import UniformTypeIdentifiers
import XemuCore
import SwiftData
import XemuFoundation

class ImportExportService {
    static let shared = ImportExportService()
    
    public func importGame(_ title: String, data: Data) throws(XemuError) -> Game {
        guard let url = URL(string: title) else {
            throw .unsuportedFileExtension
        }
        
        let fileExtension = url.pathExtension
        
        return switch fileExtension {
            case "nes":
                handleGame(url: url, data, system: .nes)
            default:
                throw .unsuportedFileExtension
        }
    }

    public func importGame(_ url: URL) throws(XemuError) -> Game {
        let fileExtension = url.pathExtension.lowercased()
        let supportedExtensions: [String] = ["nes"]
        
        guard supportedExtensions.contains(fileExtension) else {
            throw .unsuportedFileExtension
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            throw .fileSystemError
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        guard let data = try? Data(contentsOf: url) else {
            throw .fileSystemError
        }
        
        return switch fileExtension {
            case "nes":
                handleGame(url: url, data, system: .nes)
            // TODO: add more file extension
            default:
                throw .unsuportedFileExtension
        }
    }
    
    private func handleGame(url: URL, _ data: Data, system: SystemType) -> Game {
        let filename = url.deletingPathExtension().lastPathComponent
        let identifier = XemuIdentifier(from: data)
        
        let game = Game(
            identifier: identifier,
            name: filename,
            data: data,
            system: system
        )
        
        tryFetchArtwork(for: game)
        
        return game
    }

    private func tryFetchArtwork(for game: Game) {
        guard let service = OpenVGDBService.shared else {
            return
        }
            
        Task {
            guard let artwork = await service.getArtwork(game.name, system: game.system) else {
                return
            }
            
            game.artwork = artwork
        }
    }
}
