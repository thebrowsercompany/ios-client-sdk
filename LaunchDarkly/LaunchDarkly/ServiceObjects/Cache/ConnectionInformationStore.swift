import Foundation

final class ConnectionInformationStore {
    private static let connectionInformationKey = "com.launchDarkly.ConnectionInformationStore.connectionInformationKey"

    // Persisting to UserDefaults rewrites the app's preferences file and can
    // block on a disk flush. Connection information is best-effort state for
    // the next launch and is updated from the client's thread on every
    // connection change, so writes happen on this serial queue instead of the
    // caller's thread. Reads go through the same queue to stay ordered with
    // pending writes.
    private static let storeQueue = DispatchQueue(label: "com.launchDarkly.ConnectionInformationStore.storeQueue")

    static func retrieveStoredConnectionInformation() -> ConnectionInformation? {
        storeQueue.sync {
            UserDefaults.standard.retrieve(object: ConnectionInformation.self, fromKey: ConnectionInformationStore.connectionInformationKey)
        }
    }

    static func storeConnectionInformation(connectionInformation: ConnectionInformation) {
        storeQueue.async {
            UserDefaults.standard.save(customObject: connectionInformation, forKey: ConnectionInformationStore.connectionInformationKey)
        }
    }
}

private extension UserDefaults {
    func save<T: Encodable>(customObject object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            self.set(encoded, forKey: key)
        }
    }

    func retrieve<T: Decodable>(object type: T.Type, fromKey key: String) -> T? {
        guard let data = self.data(forKey: key),
            let object = try? JSONDecoder().decode(type, from: data)
        else {
            Log.debug("Couldnt decode object: \(key)")
            return nil
        }
        return object
    }
}
