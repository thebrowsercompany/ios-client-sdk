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

    let formattedMessage = formatOSLogMessage(message, arguments: args)
    let output = "[\(log.subsystem):\(log.category)] \(type.name): \(formattedMessage)\n"
    output.withCString(encodedAs: UTF16.self) {
        OutputDebugStringW($0)
    }
}

func formatOSLogMessage(_ message: StaticString, arguments: [CVarArg]) -> String {
    let format = message.description
    guard !arguments.isEmpty else { return format }

    var result = ""
    var argumentIndex = 0
    var index = format.startIndex

    while index < format.endIndex {
        guard format[index] == "%" else {
            result.append(format[index])
            index = format.index(after: index)
            continue
        }

        let placeholderStart = index
        index = format.index(after: index)
        guard index < format.endIndex else {
            result.append("%")
            break
        }

        if format[index] == "%" {
            result.append("%")
            index = format.index(after: index)
            continue
        }

        var placeholderEnd = index
        if format[placeholderEnd] == "{" {
            guard let closingBrace = format[placeholderEnd...].firstIndex(of: "}") else {
                result.append("%")
                continue
            }
            placeholderEnd = format.index(after: closingBrace)
        }

        while placeholderEnd < format.endIndex {
            let character = format[placeholderEnd]
            placeholderEnd = format.index(after: placeholderEnd)

            guard OSLogFormat.conversionSpecifiers.contains(character) else {
                continue
            }

            if argumentIndex < arguments.count {
                result.append(String(describing: arguments[argumentIndex]))
                argumentIndex += 1
            } else {
                result.append(contentsOf: format[placeholderStart..<placeholderEnd])
            }

            index = placeholderEnd
            break
        }

        if index != placeholderEnd {
            result.append("%")
        }
    }

    return result
}

private enum OSLogFormat {
    static let conversionSpecifiers: Set<Character> = [
        "@", "d", "i", "u", "o", "x", "X", "f", "F", "e", "E", "g", "G", "a", "A", "c", "C", "s", "S", "p"
    ]
}
#endif
