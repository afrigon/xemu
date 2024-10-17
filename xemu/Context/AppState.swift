import XemuCore

enum AppState {
    case loading
    case error(XemuError)
    case menu
    case gaming(Game)
}
