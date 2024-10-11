import XemuCore

public class XemuPersistanceService {
    private let store: LocalStorage
    private let remoteStore: RemoteStorage?
    
    public init(store: LocalStorage, remoteStore: RemoteStorage? = nil) {
        self.store = store
        self.remoteStore = remoteStore
    }
}
