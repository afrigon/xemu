import XemuCore
import XemuFoundation

enum AppState {
    case loading
    case error(XemuError)
    case menu
    case gaming(Game)
}
