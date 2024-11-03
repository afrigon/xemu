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
                        Text("Mapper: \(iNes.mapper)")
                        Text("Mirroring: \(iNes.nametableLayout)")
                        Text("Battery: \(iNes.hasBattery)")
                        Text("Trainer: \(iNes.hasTrainer)")
                    }
                }
            case .failure(let error):
                Text(verbatim: error.localizedDescription)
        }
    }
}
