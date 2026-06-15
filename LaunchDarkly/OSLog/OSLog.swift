#if os(Windows)
import Foundation
import WinSDK

public let osLogStringSectionName = ".rdata$oslogstring"

public struct OSLog: Sendable {
    public static let `default` = OSLog(subsystem: "default", category: "default")
    public static let disabled = OSLog(subsystem: "disabled", category: "disabled", isEnabled: false)

    public let subsystem: String
    public let category: String
    fileprivate let isEnabled: Bool

    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
        self.isEnabled = true
    }

    private init(subsystem: String, category: String, isEnabled: Bool) {
        self.subsystem = subsystem
        self.category = category
        self.isEnabled = isEnabled
    }
}

public struct OSLogType: Sendable {
    public static let `default` = OSLogType(name: "default")
    public static let debug = OSLogType(name: "debug")
    public static let info = OSLogType(name: "info")
    public static let error = OSLogType(name: "error")

    public let name: String
}

public func os_log(_ message: StaticString, log: OSLog = .default, type: OSLogType = .default, _ args: CVarArg...) {
    guard log.isEnabled else { return }

    let output = "[\(log.subsystem):\(log.category)] \(type.name): \(message.description)\n"
    output.withCString(encodedAs: UTF16.self) {
        OutputDebugStringW($0)
    }
}
#endif
