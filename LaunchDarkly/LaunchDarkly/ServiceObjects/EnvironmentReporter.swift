import Foundation

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(OSX)
import AppKit
#elseif os(tvOS)
import UIKit
#endif

// Windows must be listed explicitly so automatic environment targeting and streaming capabilities
// describe Dia Windows rather than falling through to unknown with disabled defaults.
enum OperatingSystem: String {
  case iOS, watchOS, macOS, tvOS, Windows, unknown

  static var allOperatingSystems: [OperatingSystem] {
    [.iOS, .watchOS, .macOS, .tvOS, .Windows]
  }

  var isBackgroundEnabled: Bool {
    OperatingSystem.backgroundEnabledOperatingSystems.contains(self)
  }
  static var backgroundEnabledOperatingSystems: [OperatingSystem] {
    // Desktop Windows continues to fetch and publish flags while its windows are not foregrounded.
    [.macOS, .Windows]
  }

  var isStreamingEnabled: Bool {
    OperatingSystem.streamingEnabledOperatingSystems.contains(self)
  }
  static var streamingEnabledOperatingSystems: [OperatingSystem] {
    // Dia observes live flag changes, so Windows must enable the SDK's streaming path.
    [.iOS, .macOS, .tvOS, .Windows]
  }
}

// sourcery: autoMockable
protocol EnvironmentReporting {
    // sourcery: defaultMockValue = Constants.applicationInfo
    var applicationInfo: ApplicationInfo { get }
    // sourcery: defaultMockValue = true
    var isDebugBuild: Bool { get }
    // sourcery: defaultMockValue = Constants.deviceModel
    var deviceModel: String { get }
    // sourcery: defaultMockValue = Constants.systemVersion
    var systemVersion: String { get }
    // sourcery: defaultMockValue = Constants.vendorUUID
    var vendorUUID: String? { get }
    // sourcery: defaultMockValue = Constants.manufacturer
    var manufacturer: String { get }
    // sourcery: defaultMockValue = Constants.locale
    var locale: String { get }
    // sourcery: defaultMockValue = Constants.osFamily
    var osFamily: String { get }
}
