#if os(Windows)
import Foundation
import WinSDK

class WindowsEnvironmentReporter: EnvironmentReporterChainBase {
  override var applicationInfo: ApplicationInfo {
    var info = ApplicationInfo()
    info.applicationIdentifier(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String)
    info.applicationVersion(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
    info.applicationName(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
    info.applicationVersionName(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)

    if info.applicationId == nil {
      info = super.applicationInfo
    }
    return info
  }

  override var manufacturer: String {
    "unknown"
  }

  override var systemVersion: String {
    let version = ProcessInfo.processInfo.operatingSystemVersion

    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
  }

  override var osFamily: String {
    "Windows"
  }

  override var deviceModel: String {
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
