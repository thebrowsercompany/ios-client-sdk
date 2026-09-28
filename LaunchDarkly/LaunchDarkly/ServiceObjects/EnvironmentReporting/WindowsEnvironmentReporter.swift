#if os(Windows)
import Foundation
import WinSDK

// Supplies the automatic environment attributes Dia uses for flag targeting. Generic SDK fallbacks
// would identify Windows devices as unknown and could put those clients in the wrong targeting segment.
class WindowsEnvironmentReporter: EnvironmentReporterChainBase {
    override var applicationInfo: ApplicationInfo {
        // Use bundle metadata when the embedding app provides it; preserve the SDK fallback when
        // Windows packaging omits an Info.plist so application identification is never empty.
        var info = ApplicationInfo()
        info.applicationIdentifier(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String)
        info.applicationVersion(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        info.applicationName(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
        info.applicationVersionName(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        return info.applicationId == nil ? super.applicationInfo : info
    }

    // Win32 has no stable manufacturer field for both physical PCs and virtual machines.
    override var manufacturer: String { "unknown" }

    override var systemVersion: String {
        // Match the SDK's dotted OS-version attribute shape for LaunchDarkly targeting rules.
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    // Distinguish this client from the Apple reporters' OS families in automatic context attributes.
    override var osFamily: String { "Windows" }

    override var deviceModel: String {
        var status = SYSTEM_POWER_STATUS()
        guard GetSystemPowerStatus(&status) else { return "unknown" }
        // ACLineStatus only describes the current power source: a plugged-in laptop and a desktop both report AC.
        // BatteryFlag reports whether Windows sees a system battery, which is a better device-type approximation.
        // An unknown battery status must stay unknown rather than being misclassified as a desktop.
        switch status.BatteryFlag {
        case 255: return "unknown"
        case let flag where flag & 128 != 0: return "desktop" // BATTERY_FLAG_NO_BATTERY.
        default: return "laptop"
        }
    }
}
#endif
