import Foundation

// sourcery: autoMockable
protocol DiagnosticCaching {
    var lastStats: DiagnosticStats? { get }

    func getDiagnosticId() -> DiagnosticId
    func getCurrentStatsAndReset() -> DiagnosticStats
    func incrementDroppedEventCount()
    func recordEventsInLastBatch(eventsInLastBatch: Int)
    func addStreamInit(streamInit: DiagnosticStreamInit)
}

final class DiagnosticCache: DiagnosticCaching {
    private static let diagnosticDataKey = "com.launchdarkly.DiagnosticCache.diagnosticData"
    private static let cacheQueueLabel = "com.launchdarkly.DiagnosticCache.cacheQueue"

    private let sdkKey: String
    private let dataKey: String

    private(set) var lastStats: DiagnosticStats?

    // Shared across instances: a new cache must observe updates still pending
    // from a previous instance for the same stored data.
    private static let cacheQueue = DispatchQueue(label: cacheQueueLabel)

    init(sdkKey: String) {
        self.sdkKey = sdkKey
        self.dataKey = "\(DiagnosticCache.diagnosticDataKey).\(sdkKey)"

        // Runs synchronously so the stored data is reset when init returns,
        // ordered behind any updates a previous instance queued.
        Self.cacheQueue.sync {
            if let storedData = StoreData.load(from: dataKey) {
                let oldId = DiagnosticId(diagnosticId: storedData.instanceId, sdkKey: sdkKey)
                lastStats = DiagnosticStats(id: oldId, creationDate: Date().millisSince1970, dataSinceDate: storedData.dataSinceDate, droppedEvents: storedData.droppedEvents, eventsInLastBatch: storedData.eventsInLastBatch, streamInits: storedData.streamInits)
            }
            StoreData.defaultWithRandomId().save(dataKey)
        }
    }

    /// Blocks until updates queued so far have been written, e.g. before the
    /// owning client shuts down.
    static func waitForPendingWrites() {
        cacheQueue.sync { }
    }

    func getDiagnosticId() -> DiagnosticId {
        let stored = Self.cacheQueue.sync { loadOrSetup() }
        return DiagnosticId(diagnosticId: stored.instanceId, sdkKey: sdkKey)
    }

    func getCurrentStatsAndReset() -> DiagnosticStats {
        let now = Date().millisSince1970
        // swiftlint:disable:next implicitly_unwrapped_optional
        var stored: StoreData!
        Self.cacheQueue.sync {
            stored = loadOrSetup()
            updateStoredData {
                $0.dataSinceDate = now
                $0.droppedEvents = 0
                $0.eventsInLastBatch = 0
                $0.streamInits = []
            }
        }
        return DiagnosticStats(id: DiagnosticId(diagnosticId: stored.instanceId, sdkKey: sdkKey),
                               creationDate: now,
                               dataSinceDate: stored.dataSinceDate,
                               droppedEvents: stored.droppedEvents,
                               eventsInLastBatch: stored.eventsInLastBatch,
                               streamInits: stored.streamInits)
    }

    func incrementDroppedEventCount() {
        updateStoredDataAsync { $0.droppedEvents += 1 }
    }

    func recordEventsInLastBatch(eventsInLastBatch: Int) {
        updateStoredDataAsync { $0.eventsInLastBatch = eventsInLastBatch }
    }

    func addStreamInit(streamInit: DiagnosticStreamInit) {
        updateStoredDataAsync { $0.streamInits.append(streamInit) }
    }

    private func loadOrSetup() -> StoreData {
        let stored = StoreData.load(from: dataKey)
        if let storeData = stored {
            return storeData
        } else {
            let new = StoreData.defaultWithRandomId()
            new.save(dataKey)
            return new
        }
    }

    // These updates rewrite the app's preferences file and can block on a
    // disk flush; they carry no result, so callers do not wait for them.
    // The serial cache queue keeps them ordered with the synchronous readers.
    private func updateStoredDataAsync(updateFunc: @escaping (inout StoreData) -> Void) {
        Self.cacheQueue.async { self.updateStoredData(updateFunc: updateFunc) }
    }

    private func updateStoredData(updateFunc: (inout StoreData) -> Void) {
        var storeData = StoreData.load(from: dataKey) ?? StoreData.defaultWithRandomId()
        updateFunc(&storeData)
        storeData.save(dataKey)
    }
}

private struct StoreData: Codable {
    let instanceId: String
    var dataSinceDate: Int64
    var droppedEvents: Int
    var eventsInLastBatch: Int
    var streamInits: [DiagnosticStreamInit]

    static func defaultWithRandomId() -> StoreData {
        StoreData(instanceId: UUID().uuidString, dataSinceDate: Date().millisSince1970, droppedEvents: 0, eventsInLastBatch: 0, streamInits: [])
    }

    static func load(from: String) -> StoreData? {
        let defaults = UserDefaults.standard
        if let storedData = defaults.data(forKey: from) {
            do {
                return try JSONDecoder().decode(self, from: storedData)
            } catch {
                defaults.removeObject(forKey: from)
            }
        }
        return nil
    }

    func save(_ toKey: String) {
        let defaults = UserDefaults.standard
        do {
            let encoded: Data = try JSONEncoder().encode(self)
            defaults.set(encoded, forKey: toKey)
        } catch {}
    }
}
