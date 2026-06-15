#if os(Windows)
import XCTest

@testable import OSLog

final class OSLogTest: XCTestCase {
    func testFormatMessageIncludesArguments() {
        let formatted = formatOSLogMessage(
            "%s %d %f %@",
            arguments: ["alpha", 7, 1.25, "omega"])

        XCTAssertEqual(formatted, "alpha 7 1.25 omega")
    }

    func testFormatMessageHandlesEscapedPercentAndPrivacyAnnotations() {
        let formatted = formatOSLogMessage(
            "ready %% %{bool}d",
            arguments: [true])

        XCTAssertEqual(formatted, "ready % true")
    }

    func testFormatMessageLeavesMissingPlaceholdersVisible() {
        let formatted = formatOSLogMessage(
            "%s %d",
            arguments: ["alpha"])

        XCTAssertEqual(formatted, "alpha %d")
    }
}
#endif
