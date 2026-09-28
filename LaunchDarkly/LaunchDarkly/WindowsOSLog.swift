#if os(Windows)
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

// SDK messages can contain flag values and context attributes; Windows logging needs redaction before it can be enabled.
public func os_log(_ message: StaticString, log: OSLog = .default, type: OSLogType = .default, _ args: CVarArg...) {}
#endif
