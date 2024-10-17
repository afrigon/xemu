import SwiftUI

enum XemuError: Int, Error {
    case initializationError = 6000
    case remoteConfigError
    case unsuportedFileExtension
    case fileSystemError
    case importError
    case openVGDBError

    var domain: String {
        "app.frigon.xemu.XemuError"
    }

    var code: Int {
        rawValue
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
            case .importError:
                "Something went wrong while trying to import the file."
            case .openVGDBError:
                "Something went wrong while accessing the game database."
        }
    }
}
