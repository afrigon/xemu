import Observation
//import FirebaseCore
//import FirebaseAnalytics
//import FirebaseCrashlytics
//import FirebaseRemoteConfig

@Observable
class AppContext {
    private(set) var state: AppState
//    private var remoteConfig: RemoteConfig?
    private var initialized: Bool = false
    var error: XemuError? = nil

    init() {
        state = .loading
    }
    
    func set(state: AppState) {
        if case .error(_) = self.state {
            return
        }
        
        self.state = state
    }
    
    @MainActor func setup() async {
        guard !initialized else {
            return
        }

        setupFirebase()
            
        initialized = true
        set(state: .menu)
    }
    
    private func setupFirebase() {
//        FirebaseApp.configure()
//        
//        remoteConfig = RemoteConfig.remoteConfig()
//        remoteConfig?.addOnConfigUpdateListener { configUpdate, error in
//            guard error == nil else {
//                print("Error listening for config updates: \(String(describing: error))")
//                return
//            }
//            
//            self.remoteConfig?.activate { changed, error in
//                guard error == nil else {
//                    return self.state = .error(.remoteConfigError)
//                }
//            }
//        }
    }
}
