import Foundation

/// Only a real system sleep starts protection. Screen saver/display events never do.
/// Wake notifications alone cannot release it: maintenance wake may deliver callbacks too.
struct RemoteSleepConnectionPolicy {
    enum Phase: String { case idle, isolating, isolated, failed }
    private(set) var phase: Phase = .idle
    private(set) var target: UUID?
    private(set) var systemAwake = true
    private(set) var operation = 0

    mutating func beginSleep(target: UUID?) -> Bool {
        systemAwake = false
        // Keep the same operation through repeated sleep/maintenance notifications.
        guard self.target == nil, let target else { return false }
        self.target = target
        operation += 1
        phase = .isolating
        return true
    }

    mutating func finishIsolation(operation: Int, succeeded: Bool) {
        guard self.operation == operation, target != nil else { return }
        phase = succeeded ? .isolated : .failed
    }

    mutating func didWake() { systemAwake = true }

    mutating func releaseIfInteractive(displayAwake: Bool, sessionActive: Bool) -> UUID? {
        guard systemAwake, displayAwake, sessionActive else { return nil }
        return release()
    }

    mutating func release() -> UUID? {
        let previous = target
        target = nil
        phase = .idle
        operation += 1 // Invalidate a late isolation completion.
        return previous
    }
}

/// Discovery remains armed after isolation release until READY or suspension.
/// Idle peripherals are not failures: avoid exponential gaps that miss button broadcasts.
struct RemoteSleepReconnectPolicy {
    static let discoveryWindow: TimeInterval = 20
    static let retryDelay: TimeInterval = 0.5
    static let connectionFailureDelay: TimeInterval = 3
    private(set) var pending = false
    mutating func prepare(hasSavedTarget: Bool) { pending = hasSavedTarget }
    var shouldDiscover: Bool { pending }
    func retryDelayIfActive(enabledForTarget: Bool) -> TimeInterval? {
        pending && enabledForTarget ? Self.connectionFailureDelay : nil
    }
    mutating func reset() { pending = false }
}
