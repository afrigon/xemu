import SwiftUI

enum XemuError: Error {
    case initializationError
    case remoteConfigError
    case unsuportedFileExtension
    case fileSystemError

    var domain: String {
        "app.frigon.xemu.XemuError"
    }

    var code: Int {
        switch self {
            case .initializationError:
                6001
            case .remoteConfigError:
                6002
            case .unsuportedFileExtension:
                6003
            case .fileSystemError:
                6004
        }
    }

    var message: LocalizedStringKey {
        switch self {
            case .initializationError:
                "An unexpected error occurred during initialization."
            case .remoteConfigError:
                "Something went wrong while loading remote config."
            case .unsuportedFileExtension:
                "Could not open this file, the format provided is unsuported."
            case .fileSystemError:
                "Something went wrong while trying to access the file system."
        }
    }
}
