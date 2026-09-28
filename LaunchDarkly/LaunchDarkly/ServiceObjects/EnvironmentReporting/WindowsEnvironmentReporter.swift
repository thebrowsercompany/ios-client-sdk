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
        return info.applicationId == nil ? super.applicationInfo : info
    }

    override var manufacturer: String { "unknown" }

    override var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    override var osFamily: String { "Windows" }

    override var deviceModel: String {
        var status = SYSTEM_POWER_STATUS()
        guard GetSystemPowerStatus(&status) else { return "unknown" }
        switch status.ACLineStatus {
        case 0, 1: return "laptop"
        case 255: return "desktop"
        default: return "unknown"
        }
    }
}
#endif
