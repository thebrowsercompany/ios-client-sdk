#if os(Windows)
// Windows Swift has no Apple OSLog module. Keep these compatibility symbols inside LaunchDarkly:
// publishing a separate OSLog module makes unrelated packages think Apple's logging API is available.
/// The section used for OSLog string literals on Windows.
public let osLogStringSectionName = ".rdata$oslogstring"

/// An SDK-local logging category for Windows.
public struct OSLog {
    /// The default Windows logging category.
    public static let `default` = OSLog(subsystem: "", category: "")

    /// Creates a Windows logging category.
    public init(subsystem: String, category: String) {}
}

/// A logging severity for Windows compatibility.
public struct OSLogType {
    /// The default logging severity.
    public static let `default` = OSLogType()
    /// The debug logging severity.
    public static let debug = OSLogType()
    /// The informational logging severity.
    public static let info = OSLogType()
    /// The error logging severity.
    public static let error = OSLogType()
}

// LaunchDarkly's messages can include flag values and context attributes. Do not forward them to an
// application logger or another sink until each call site is checked for private data and has a redaction policy.
/// Discards SDK log messages on Windows.
public func os_log(_ message: StaticString, log: OSLog = .default, type: OSLogType = .default, _ args: CVarArg...) {}
#endif
