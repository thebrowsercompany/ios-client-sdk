#if os(Windows)
// Windows Swift has no Apple OSLog module. Keep these compatibility symbols inside LaunchDarkly:
// publishing a separate OSLog module makes unrelated packages think Apple's logging API is available.
public let osLogStringSectionName = ".rdata$oslogstring"

public struct OSLog {
    public static let `default` = OSLog(subsystem: "", category: "")

    public init(subsystem: String, category: String) {}
}

public struct OSLogType {
    public static let `default` = OSLogType()
    public static let debug = OSLogType()
    public static let info = OSLogType()
    public static let error = OSLogType()
}

// LaunchDarkly's messages can include flag values and context attributes. Do not forward them to an
// application logger or another sink until each call site is checked for private data and has a redaction policy.
public func os_log(_ message: StaticString, log: OSLog = .default, type: OSLogType = .default, _ args: CVarArg...) {}
#endif
