import Foundation

/// A lightweight utility for executing asynchronous operations with a timeout fallback.
///
/// `TimeoutExecutor` guarantees that the provided `completion` closure is called **exactly once**,
/// either with the result of the asynchronous operation or with a timeout value if the operation
/// does not complete in time.
///
/// ### Typical Usage
/// ```swift
/// TimeoutExecutor.run(
///     timeout: 2.0,
///     queue: .main,
///     operation: { done in
///          service.action() {
///                     done("Success")
///          }
///     },
///     timeoutValue: "Timeout",
///     completion: { result in
///         print("Result:", result)
///     }
/// )
/// ```
///
final class TimeoutExecutor {
    private init() {}

    static func run<T>(
        timeout: TimeInterval,
        queue: DispatchQueue = .global(),
        operation: (@escaping (T) -> Void) -> Void,
        timeoutValue: @autoclosure @escaping () -> T,
        completion: ((T) -> Void)?
    ) {
        guard let completion = completion else {
            operation { _ in
                /* ignore result */
            }
            return
        }
        
        let lockQueue = DispatchQueue(label: "launchdarkly.timeout.executor.lock")
        var finished = false

        func finish(_ value: @autoclosure () -> T) {
            var shouldCall = false
            lockQueue.sync {
                if !finished {
                    finished = true
                    shouldCall = true
                }
            }
            guard shouldCall else { return }
            queue.async { completion(timeoutValue()) }
        }

        // Start the user operation (they can call `done` from any queue)
        operation { value in
            finish(value)
        }

        // Timeout fallback scheduled
        queue.asyncAfter(deadline: .now() + timeout) {
            finish(timeoutValue())
        }
    }
}
