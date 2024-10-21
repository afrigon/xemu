import SwiftUI

extension LocalizedStringKey {
    public var stringKey: String? {
        Mirror(reflecting: self)
            .children
            .first(where: { $0.label == "key" })?
            .value as? String
    }
}
