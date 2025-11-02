import Foundation

final class LockedAccumulator: @unchecked Sendable {
    
    nonisolated(unsafe) static var shared = LockedAccumulator(start: 0)
    
    private var current: Int
    private let lock = NSLock()

    private init(start: Int = 0) {
        self.current = start
    }

    @discardableResult
    public func next(by step: Int = 1) -> Int {
        lock.lock(); defer { lock.unlock() }
        current += step
        return current
    }

    public func value() -> Int {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    public func reset(to value: Int = 0) {
        lock.lock(); defer { lock.unlock() }
        current = value
    }
}
