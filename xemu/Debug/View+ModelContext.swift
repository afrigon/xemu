import SwiftUI
import SwiftData

extension View {
    func mockData<T: PersistentModel>(for type: T.Type, _ populate: () -> [T]) -> some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: type.self, configurations: config)
        
        let items = populate()
        
        for item in items {
            container.mainContext.insert(item)
        }
        
        return modelContainer(container)
    }
}
