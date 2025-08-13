#if os(Windows)

import Foundation

// Define types to match os_log API
public struct OSLog {
    public let subsystem: String
    public let category: String
    public init(subsystem: String = "", category: String = "") {
        self.subsystem = subsystem
        self.category = category
    }
}

public enum OSLogType: Int {
    case `default`
    case info
    case debug
    case error
    case fault
}

// Shim for os_log
@inline(__always)
public func os_log(
    _ message: StaticString,
    log: OSLog = OSLog(),
    type: OSLogType = .default,
    _ args: CVarArg...
) {
    // Format the message
    let formatString = String(describing: message)
    let formatted = String(format: formatString, arguments: args)
    let typeString: String
    switch type {
    case .default: typeString = "DEFAULT"
    case .info:    typeString = "INFO"
    case .debug:   typeString = "DEBUG"
    case .error:   typeString = "ERROR"
    case .fault:   typeString = "FAULT"
    }
    let logPrefix = "[\(typeString)][\(log.subsystem):\(log.category)]"
    print("\(logPrefix) \(formatted)")
}

#endif