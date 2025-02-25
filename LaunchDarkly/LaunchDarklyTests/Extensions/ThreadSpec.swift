import Foundation
import Quick
import Nimble
@testable import LaunchDarkly

final class ThreadSpec: QuickSpec {
    override class func spec() {
        performOnMainSpec()
    }

    private class func performOnMainSpec() {
        var runCount = 0
        var ranOnMainThread = false
        describe("performOnMain") {
            context("when on the main thread") {
                beforeEach {
                    runCount = 0
                    ranOnMainThread = false
                    Thread.performOnMain {
                        runCount += 1
                        ranOnMainThread = Thread.isMainThread
                    }
                }
                it("executes the closure synchronously on the main thread") {
                    expect(runCount) == 1
                    expect(ranOnMainThread) == true
                }
            }
            context("when off the main thread") {
                var backgroundQueue: DispatchQueue!
                beforeEach {
                    runCount = 0
                    ranOnMainThread = false
                    backgroundQueue = DispatchQueue(label: "com.launchdarkly.tests.ThreadSpec.backgroundQueue", qos: .utility)
                    waitUntil { done in
                        backgroundQueue.async {
                            Thread.performOnMain {
                                runCount += 1
                                ranOnMainThread = Thread.isMainThread
                                done()
                            }
                        }
                    }
                }
                it("executes the closure synchronously on the main thread") {
                    expect(runCount) == 1
                    expect(ranOnMainThread) == true
                }
            }
        }
    }
}
