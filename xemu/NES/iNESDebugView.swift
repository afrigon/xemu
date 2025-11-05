import SwiftUI
import XemuNES
import XemuFoundation

struct iNesDebugView: View {
    let result: Result<iNesFile, XemuError>
    
    init(game: Data) {
        do throws(XemuError) {
            result = .success(try iNesFile(game))
        } catch let error {
            result = .failure(error)
        }
    }
    
    var body: some View {
        switch result {
            case .success(let iNes):
                List {
                    Section(header: Text("Header")) {
                        Text(verbatim: "Mapper: \(iNes.mapper)")
                        Text(verbatim: "Mirroring: \(iNes.nametableLayout)")
                        Text(verbatim: "Battery: \(iNes.hasBattery)")
                        Text(verbatim: "Trainer: \(iNes.hasTrainer)")
                    }
                }
            case .failure(let error):
                Text(verbatim: error.localizedDescription)
        }
    }
}
