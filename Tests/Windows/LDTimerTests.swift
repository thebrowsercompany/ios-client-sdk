import Foundation
@testable import LaunchDarkly
import WinSDK
import XCTest

final class LDTimerTests: XCTestCase {
    func testRepeatsOnRequestedQueueWithoutFoundationRunLoop() throws {
        let driver = try TimerTestDriver()
        driver.start()
        let firstFireDate = try XCTUnwrap(driver.timer?.fireDate)

        XCTAssertTrue(driver.waitForTick())
        XCTAssertTrue(driver.waitForTick())
        XCTAssertGreaterThan(try XCTUnwrap(driver.timer?.fireDate), firstFireDate)
    }

    func testHonorsFutureFireDate() throws {
        let driver = try TimerTestDriver()
        let fireDate = Date(timeIntervalSinceNow: 0.1)
        var firedAt: Date?
        driver.start(interval: 60, fireAt: fireDate) { firedAt = Date() }

        XCTAssertEqual(driver.timer?.fireDate, fireDate)
        XCTAssertTrue(driver.waitForTick())
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(driver.queue.sync { firedAt }), fireDate)
    }

    func testPastFireDateFiresImmediately() throws {
        let driver = try TimerTestDriver()
        driver.start(interval: 60, fireAt: .distantPast)

        XCTAssertTrue(driver.waitForTick())
        XCTAssertGreaterThan(try XCTUnwrap(driver.timer?.fireDate), Date())
    }

    func testCancellationStopsCallbacks() throws {
        let driver = try TimerTestDriver()
        driver.start()
        XCTAssertTrue(driver.waitForTick())

        driver.timer?.cancel()
        driver.timer?.cancel()
        driver.drainCallbacks()

        XCTAssertNil(driver.timer?.fireDate)
        XCTAssertFalse(driver.waitForTick(timeout: 50))
    }

    func testDeallocationStopsCallbacks() throws {
        let driver = try TimerTestDriver()
        driver.start()
        XCTAssertTrue(driver.waitForTick())

        driver.timer = nil
        driver.drainCallbacks()

        XCTAssertFalse(driver.waitForTick(timeout: 50))
    }

    func testCanCancelFromCallback() throws {
        let driver = try TimerTestDriver()
        driver.start { [weak driver] in driver?.timer?.cancel() }

        XCTAssertTrue(driver.waitForTick())
        driver.drainCallbacks()
        XCTAssertNil(driver.timer?.fireDate)
        XCTAssertFalse(driver.waitForTick(timeout: 50))
    }
}

private final class TimerTestDriver {
    let queue = DispatchQueue(label: "LDTimerTests")
    let ticks: HANDLE
    var timer: LDTimer?

    init() throws {
        ticks = try XCTUnwrap(CreateSemaphoreW(nil, 0, Int32.max, nil))
    }

    deinit {
        timer?.cancel()
        timer = nil
        queue.sync {}
        CloseHandle(ticks)
    }

    func start(interval: TimeInterval = 0.005, fireAt: Date? = nil, onFire: (() -> Void)? = nil) {
        let queue = queue
        let ticks = ticks
        queue.sync {
            timer = LDTimer(withTimeInterval: interval, fireQueue: queue, fireAt: fireAt) {
                dispatchPrecondition(condition: .onQueue(queue))
                onFire?()
                ReleaseSemaphore(ticks, 1, nil)
            }
        }
    }

    func waitForTick(timeout: DWORD = 1000) -> Bool {
        // A kernel wait leaves Foundation's main run loop unserviced.
        WaitForSingleObject(ticks, timeout) == WAIT_OBJECT_0
    }

    func drainCallbacks() {
        queue.sync {}
        while waitForTick(timeout: 0) {}
    }
}
