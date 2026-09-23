import Foundation
import XCTest

@testable import LaunchDarkly

/// Plain-XCTest coverage for the asynchronous persistence paths, runnable on
/// platforms where the Quick-based specs do not execute (e.g. Windows).
final class DiagnosticCachePersistenceTests: XCTestCase {
    private let sdkKey = "persistence_tests_fake_key"
    private var dataKey: String { "com.launchdarkly.DiagnosticCache.diagnosticData.\(sdkKey)" }

    override func setUp() {
        super.setUp()
        clearState()
    }

    override func tearDown() {
        clearState()
        super.tearDown()
    }

    private func clearState() {
        DiagnosticCache.waitForPendingWrites()
        ConnectionInformationStore.waitForPendingWrites()
        UserDefaults.standard.removeObject(forKey: dataKey)
        UserDefaults.standard.removeObject(forKey: "com.launchDarkly.ConnectionInformationStore.connectionInformationKey")
    }

    func testInitResetsStoredDataBeforeReturning() {
        _ = DiagnosticCache(sdkKey: sdkKey)
        XCTAssertNotNil(UserDefaults.standard.data(forKey: dataKey))
    }

    func testRecreatedCacheObservesPendingUpdates() {
        let first = DiagnosticCache(sdkKey: sdkKey)
        first.incrementDroppedEventCount()
        first.recordEventsInLastBatch(eventsInLastBatch: 7)
        first.addStreamInit(streamInit: DiagnosticStreamInit(timestamp: 42, durationMillis: 5, failed: true))

        let second = DiagnosticCache(sdkKey: sdkKey)
        let lastStats = second.lastStats
        XCTAssertNotNil(lastStats)
        XCTAssertEqual(lastStats?.droppedEvents, 1)
        XCTAssertEqual(lastStats?.eventsInLastBatch, 7)
        XCTAssertEqual(lastStats?.streamInits.count, 1)
        XCTAssertEqual(lastStats?.streamInits.first?.timestamp, 42)
    }

    func testWaitForPendingWritesMakesUpdatesDurable() {
        let cache = DiagnosticCache(sdkKey: sdkKey)
        cache.incrementDroppedEventCount()
        DiagnosticCache.waitForPendingWrites()
        guard let stored = UserDefaults.standard.data(forKey: dataKey),
              let decoded = try? JSONSerialization.jsonObject(with: stored) as? [String: Any]
        else {
            XCTFail("no stored diagnostic data")
            return
        }
        XCTAssertEqual(decoded["droppedEvents"] as? Int, 1)
    }

    func testConnectionInformationRoundTripAfterDrain() {
        let connectionInformation = ConnectionInformation(currentConnectionMode: .offline, lastConnectionFailureReason: .none, lastKnownFlagValidity: Date(timeIntervalSince1970: 1234))
        ConnectionInformationStore.storeConnectionInformation(connectionInformation: connectionInformation)
        ConnectionInformationStore.waitForPendingWrites()
        let restored = ConnectionInformationStore.retrieveStoredConnectionInformation()
        XCTAssertEqual(restored?.currentConnectionMode, .offline)
        XCTAssertEqual(restored?.lastKnownFlagValidity, Date(timeIntervalSince1970: 1234))
    }
}
