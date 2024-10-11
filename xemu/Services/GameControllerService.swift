import GameController

class GameControllerService {
    static let shared = GameControllerService()
    
    var controllers: [GCController] = []
    
    func start() {
        for controller in GCController.controllers() {
            controllers.append(controller)
            // TODO: Register buttons ?
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleControllerConnected), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleControllerDisconnected), name: .GCControllerDidDisconnect, object: nil)
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidDisconnect, object: nil)
        
        controllers.removeAll()
    }
    
    @objc func handleControllerConnected(_ notification: Notification) {
        if let controller = notification.object as? GCController {
            controllers.append(controller)
        }
    }
    
    @objc func handleControllerDisconnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }
        
        if let index = controllers.firstIndex(of: controller) {
            controllers.remove(at: index)
        }
    }
}
