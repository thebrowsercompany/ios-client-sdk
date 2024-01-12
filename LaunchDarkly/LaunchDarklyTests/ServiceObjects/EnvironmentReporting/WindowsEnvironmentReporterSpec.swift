#if os(Windows)
import Foundation
import WinSDK
import XCTest

@testable import LaunchDarkly

final class WindowsEnvironmentReporterSpec: XCTestCase {
  func testDefaultReporterBehavior() {
    let chain = EnvironmentReporterChainBase()
    chain.setNext(WindowsEnvironmentReporter())

    XCTAssertEqual(chain.osFamily, "Windows")
    XCTAssertEqual(chain.deviceModel, expectedDeviceModel())
    XCTAssertEqual(chain.manufacturer, "unknown")

    let version = chain.systemVersion
    let split = version.split(separator: ".")
    XCTAssertEqual(split.count, 3)
  }

  private func expectedDeviceModel() -> String {
    var status: SYSTEM_POWER_STATUS = .init()
    if !GetSystemPowerStatus(&status) {
      return "unknown"
    }

    switch status.ACLineStatus {
      // Not using AC power, probably a laptop on battery
      case 0:
      return "laptop"
      // Using AC power, probably a laptop on AC power
      case 1:
      return "laptop"
      // AC power status unknown, likely a desktop
      case 255:
      return "desktop"
      // An unknown value, return unknown since we don't know
      default:
      return "unknown"
    }
  }
}
#endif
