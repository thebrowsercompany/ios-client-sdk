import Foundation

protocol TimeResponding {
    var fireDate: Date? { get }

    init(withTimeInterval: TimeInterval, fireQueue: DispatchQueue, fireAt: Date?, execute: @escaping () -> Void)
    func cancel()
}

#if os(Windows)
// Windows hosts can service libdispatch without running Foundation's main run loop.
final class LDTimer: TimeResponding {
    private let timer: DispatchSourceTimer
    private let lock = NSLock()
    private var nextFireDate: Date?

    var fireDate: Date? {
        lock.withLock { nextFireDate }
    }

    init(withTimeInterval timeInterval: TimeInterval, fireQueue: DispatchQueue = .main, fireAt: Date? = nil, execute: @escaping () -> Void) {
        let now = Date()
        let fireDate = max(fireAt ?? now.addingTimeInterval(timeInterval), now)
        nextFireDate = fireDate
        timer = DispatchSource.makeTimerSource(queue: fireQueue)
        timer.schedule(deadline: .now() + max(0, fireDate.timeIntervalSinceNow), repeating: timeInterval)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let shouldFire = self.lock.withLock {
                guard let fireDate = self.nextFireDate else { return false }
                let intervals = max(1, floor(Date().timeIntervalSince(fireDate) / timeInterval) + 1)
                self.nextFireDate = fireDate.addingTimeInterval(intervals * timeInterval)
                return true
            }
            if shouldFire {
                execute()
            }
        }
        timer.resume()
    }

    deinit {
        timer.cancel()
    }

    func cancel() {
        lock.withLock { nextFireDate = nil }
        timer.cancel()
    }
}
#else
final class LDTimer: TimeResponding {

    private(set) weak var timer: Timer?
    private let fireQueue: DispatchQueue
    private let execute: () -> Void
    private(set) var isCancelled: Bool = false
    var fireDate: Date? { timer?.fireDate }

    init(withTimeInterval timeInterval: TimeInterval, fireQueue: DispatchQueue = DispatchQueue.main, fireAt: Date? = nil, execute: @escaping () -> Void) {
        self.fireQueue = fireQueue
        self.execute = execute

        // the run loop retains the timer, so the property is weak to avoid a retain cycle. Setting the timer to a strong reference is important so that the timer doesn't get nil'd before it's added to the run loop.
        let timer: Timer
        if let at = fireAt {
            timer = Timer(fireAt: at, interval: timeInterval, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        } else {
            timer = Timer(timeInterval: timeInterval, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
    }

    deinit {
        timer?.invalidate()
    }

    @objc
    private func timerFired() {
        fireQueue.async { [weak self] in
            guard (self?.isCancelled ?? true) == false
            else { return }
            self?.execute()
        }
    }

    func cancel() {
        timer?.invalidate()
        isCancelled = true
    }
}
#endif
