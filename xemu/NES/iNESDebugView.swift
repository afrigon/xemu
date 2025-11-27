import Foundation
import SwiftUI
import XemuNES
import XemuFoundation
import XemuCore

struct iNesDebugView: View {
    @Environment(\.dismiss) var dismiss
    
    let result: Result<iNesFile, XemuError>
    let game: Game
    
    init(game: Game) {
        self.game = game
        
        do throws(XemuError) {
            result = .success(try iNesFile(game.data))
        } catch let error {
            result = .failure(error)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: .zero) {
                switch result {
                    case .success(let iNes):
                        List {
                            Section(
                                content: {
                                    createRow(
                                        title: "File Name",
                                        subtitle: "\(game.fileName)"
                                    )
                                    
                                    createRow(
                                        title: "File Type",
                                        subtitle: "\(iNes.version)"
                                    )
                                    
                                    createRow(
                                        title: "File Size",
                                        subtitle: "\(game.data.count.formatted(.byteCount(style: .file)))"
                                    )
                                },
                                header: {
                                    Text("File")
                                        .textStyle(.subtitle)
                                        .foregroundStyle(.foregroundMuted)
                                }
                            )
                            
                            Section(
                                content: {
                                    createRow(
                                        title: "Console Type",
                                        subtitle: "\(iNes.consoleType.description)"
                                    )
                                    
                                    createRow(
                                        title: "Battery",
                                        subtitle: "\(iNes.hasBattery)"
                                    )
                                    
                                    createRow(
                                        title: "Trainer",
                                        subtitle: "\(iNes.hasTrainer)"
                                    )
                                    
                                    createRow(
                                        title: "Mirroring",
                                        subtitle: "\(iNes.mirroringType)"
                                    )
                                    
                                    createRow(
                                        title: "Mapper",
                                        subtitle: "\(iNes.mapper) (\(iNes.mapper.rawValue))"
                                    )
                                },
                                header: {
                                    Text("Header")
                                        .textStyle(.subtitle)
                                        .foregroundStyle(.foregroundMuted)
                                }
                            )
                            
                            Section(
                                content: {
                                    createRow(
                                        title: "Program ROM",
                                        subtitle: "\(iNes.prgRomSize.formatted(.byteCount(style: .memory)))"
                                    )
                                    
                                    createRow(
                                        title: "Character ROM",
                                        subtitle: "\(iNes.chrRomSize.formatted(.byteCount(style: .memory)))"
                                    )

                                    // TODO: add ram sizes
                                },
                                header: {
                                    Text("Data")
                                        .textStyle(.subtitle)
                                        .foregroundStyle(.foregroundMuted)
                                }
                            )
                        }
                    case .failure(let error):
                        Text(verbatim: error.localizedDescription)
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Cartridge Details")
                        .textStyle(.body(.l, .bold))
                        .foregroundStyle(.foregroundDefault)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", role: .close, action: {
                        dismiss()
                    })
                    .textStyle(.body(.l, .bold))
                }
            }
        }
    }
    
    @ViewBuilder
    private func createRow(title: LocalizedStringResource, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: .xxs) {
            Text(title)
                .textStyle(.body(.l, .regular))
                .foregroundStyle(.foregroundMuted)
            Text(verbatim: subtitle)
                .textStyle(.body(.l, .bold))
                .foregroundStyle(.foregroundDefault)
        }
    }
}
