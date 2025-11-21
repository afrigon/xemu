import SwiftUI

enum AppStorageKey: String {
    case gameCollectionSorting = "settings.game-collection.sorting"
    case showFPS = "settings.advanced.show-fps"
}

extension AppStorage {
    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == Bool {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == Int {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == Double {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == URL {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value == Data {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
}

extension AppStorage {
    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value: RawRepresentable, Value.RawValue == Int {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: AppStorageKey, store: UserDefaults? = nil) where Value: RawRepresentable, Value.RawValue == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
}

extension AppStorage where Value: ExpressibleByNilLiteral {
    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == Bool? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == Int? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == Double? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == String? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == URL? {
        self.init(key.rawValue, store: store)
    }

    init(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == Data? {
        self.init(key.rawValue, store: store)
    }
}

extension AppStorage {
    init<R>(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == R?, R: RawRepresentable, R.RawValue == String {
        self.init(key.rawValue, store: store)
    }

    init<R>(_ key: AppStorageKey, store: UserDefaults? = nil) where Value == R?, R: RawRepresentable, R.RawValue == Int {
        self.init(key.rawValue, store: store)
    }
}

extension UserDefaults {
    func object(forKey key: AppStorageKey) -> Any? {
        object(forKey: key.rawValue)
    }

    func set(_ value: Any?, forKey key: AppStorageKey) {
        set(value, forKey: key.rawValue)
    }

    func removeObject(forKey key: AppStorageKey) {
        removeObject(forKey: key.rawValue)
    }

    func string(forKey key: AppStorageKey) -> String? {
        string(forKey: key.rawValue)
    }

    func array(forKey key: AppStorageKey) -> [Any]? {
        array(forKey: key.rawValue)
    }

    func dictionary(forKey key: AppStorageKey) -> [String: Any]? {
        dictionary(forKey: key.rawValue)
    }

    func data(forKey key: AppStorageKey) -> Data? {
        data(forKey: key.rawValue)
    }

    func stringArray(forKey key: AppStorageKey) -> [String]? {
        stringArray(forKey: key.rawValue)
    }

    func integer(forKey key: AppStorageKey) -> Int {
        integer(forKey: key.rawValue)
    }

    func float(forKey key: AppStorageKey) -> Float {
        float(forKey: key.rawValue)
    }

    func double(forKey key: AppStorageKey) -> Double {
        double(forKey: key.rawValue)
    }

    func bool(forKey key: AppStorageKey) -> Bool {
        bool(forKey: key.rawValue)
    }

    func url(forKey key: AppStorageKey) -> URL? {
        url(forKey: key.rawValue)
    }

    func set(_ value: Int, forKey key: AppStorageKey) {
        set(value, forKey: key.rawValue)
    }

    func set(_ value: Float, forKey key: AppStorageKey) {
        set(value, forKey: key.rawValue)
    }

    func set(_ value: Double, forKey key: AppStorageKey) {
        set(value, forKey: key.rawValue)
    }

    func set(_ value: Bool, forKey key: AppStorageKey) {
        set(value, forKey: key.rawValue)
    }

    func set(_ url: URL?, forKey key: AppStorageKey) {
        set(url, forKey: key.rawValue)
    }
}
