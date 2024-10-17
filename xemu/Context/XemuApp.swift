import SwiftUI
import SwiftData
import XemuCore

@main
struct XemuApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
#if canImport(UIKit)
                .onAppear {
                    UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(named: "AccentColor")
                }
#endif
        }
        .modelContainer(for: Game.self, isAutosaveEnabled: true)
    }
}
