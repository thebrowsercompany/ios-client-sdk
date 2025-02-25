import Foundation
import Nimble

/**
 Used by the `toMatch` matcher.

 This is the return type for the closure.
 */
public enum ToMatchResult {
    case matched
    case failed(reason: String)
}

/**
 A Nimble matcher that takes in a closure for validation.

 Return `.matched` when the validation succeeds.
 Return `.failed` with a failure reason when the validation fails.
 */
public func match() -> Matcher<() -> ToMatchResult> {
    Matcher.define { actualExpression in
        let optActual = try actualExpression.evaluate()
        guard let actual = optActual else {
            return MatcherResult(status: .fail, message: .fail("expected a closure, got <nil>"))
        }

        switch actual() {
        case .matched:
            return MatcherResult(
                bool: true,
                message: .expectedCustomValueTo("match", actual: "<matched>")
            )
        case .failed(let reason):
            return MatcherResult(
                bool: false,
                message: .expectedCustomValueTo("match", actual: "<failed> because <\(reason)>")
            )
        }
    }
}
