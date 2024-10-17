import SwiftUI

extension View {
    func mockContext() -> some View {
        environment(AppContext())
    }
}
