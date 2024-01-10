#if os(Windows)
import Foundation
import XCTest

@testable import LaunchDarkly

final class WindowsEnvironmentReporterSpec: XCTest {
  func testDefaultReporterBehavior() {
    let chain = EnvironmentReporterChainBase()
    chain.setNext(WindowsEnvironmentReporter())

    XCTAssertEqual(chain.osFamily, "Windows")
    XCTAssertEqual(chain.deviceModel, "desktop")
  }

}
#endif
