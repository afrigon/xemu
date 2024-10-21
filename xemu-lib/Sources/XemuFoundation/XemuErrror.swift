import SwiftUI

public enum XemuError: Int, Error {
    case initializationError = 6000
    case remoteConfigError
    case unsuportedFileExtension
    case fileSystemError
    case importError
    case openVGDBError
    case romError
    case illegalInstruction
    case unknownCommand
    case emulatorNotSet
    case fileFormatError
    case indexOutOfBounds
    case dataOutOfAlignment
    case notImplemented

    public var domain: String {
        "app.frigon.xemu.XemuError"
    }

    public var code: Int {
        rawValue
    }

    public var message: LocalizedStringKey {
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
            case .romError:
                "Something went wrong while loading the given rom."
            case .illegalInstruction:
                "An illegal instruction was encountered."
            case .unknownCommand:
                "Unknown Command."
            case .emulatorNotSet:
                "You need to setup an emulator before using this command."
            case .fileFormatError:
                "Something is wrong with the file format."
            case .indexOutOfBounds:
                "The index is out of bounds."
            case .dataOutOfAlignment:
                "Data cursor is out of alignment."
            case .notImplemented:
                "This feature is not implemented yet."
        }
    }
}
