import SwiftUI

struct ErrorView: View {
    let error: XemuError
    
    var body: some View {
        Text(error.message)
//            .analyticsScreen(.error)
    }
}
