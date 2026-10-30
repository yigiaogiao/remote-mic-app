import Foundation
import Testing
@testable import RemoteMic

@Suite("Remote sleep connection policy")
struct RemoteSleepConnectionPolicyTests {
    @Test func defaultOffNeverSelectsAnyDevice() {
        var policy = RemoteSleepConnectionPolicy()
        let result1 = !policy.beginSleep(target: nil)
        #expect(result1)
        #expect(policy.target == nil)
        policy.didWake()
        let result2 = policy.releaseIfInteractive(displayAwake: true, sessionActive: true) == nil
        #expect(result2)
    }

    @Test func maintenanceWakeDoesNotReleaseRemoteAndRepeatedSleepKeepsOperation() {
        let remote = UUID()
        var policy = RemoteSleepConnectionPolicy()
        let result3 = policy.beginSleep(target: remote)
        #expect(result3)
        let operation = policy.operation
        policy.finishIsolation(operation: operation, succeeded: true)
        policy.didWake()
        let result4 = policy.releaseIfInteractive(displayAwake: false, sessionActive: true) == nil
        #expect(result4)
        #expect(policy.target == remote)
        let result5 = !policy.beginSleep(target: UUID())
        #expect(result5)
        #expect(policy.operation == operation)
        #expect(policy.target == remote)
        #expect(policy.phase == .isolated)
        policy.didWake()
        let result6 = policy.releaseIfInteractive(displayAwake: true, sessionActive: true) == remote
        #expect(result6)
        #expect(policy.phase == .idle)
    }

    @Test func displayWakeAloneAndInactiveSessionCannotRestore() {
        var policy = RemoteSleepConnectionPolicy()
        let remote = UUID()
        _ = policy.beginSleep(target: remote)
        let result7 = policy.releaseIfInteractive(displayAwake: true, sessionActive: true) == nil
        #expect(result7)
        policy.didWake()
        let result8 = policy.releaseIfInteractive(displayAwake: true, sessionActive: false) == nil
        #expect(result8)
        #expect(policy.target == remote)
    }

    @Test func cancelledSleepAndDisabledFeatureInvalidateLateCompletion() {
        var policy = RemoteSleepConnectionPolicy()
        let remote = UUID()
        _ = policy.beginSleep(target: remote)
        let operation = policy.operation
        let result9 = policy.release() == remote
        #expect(result9)
        policy.finishIsolation(operation: operation, succeeded: true)
        #expect(policy.phase == .idle)
        #expect(policy.target == nil)
        _ = policy.beginSleep(target: UUID())
        policy.finishIsolation(operation: operation, succeeded: false)
        #expect(policy.phase == .isolating)
    }

    @Test func failureKeepsReconnectGateUntilInteractiveRecovery() {
        let remote = UUID()
        var policy = RemoteSleepConnectionPolicy()
        _ = policy.beginSleep(target: remote)
        policy.finishIsolation(operation: policy.operation, succeeded: false)
        #expect(policy.phase == .failed)
        #expect(policy.target == remote)
        policy.didWake()
        let result10 = policy.releaseIfInteractive(displayAwake: false, sessionActive: true) == nil
        #expect(result10)
        let result11 = policy.releaseIfInteractive(displayAwake: true, sessionActive: true) == remote
        #expect(result11)
    }

    @Test func recoveryDiscoveryPersistsAcrossRetriesUntilReadyOrSuspension() {
        var policy = RemoteSleepReconnectPolicy()
        let ordinary = policy.shouldDiscover
        #expect(!ordinary)
        policy.prepare(hasSavedTarget: false)
        let unknownTarget = policy.shouldDiscover
        #expect(!unknownTarget)
        policy.prepare(hasSavedTarget: true)
        let firstWakeAttempt = policy.shouldDiscover
        let nextAttempt = policy.shouldDiscover
        #expect(firstWakeAttempt)
        #expect(nextAttempt)
        #expect(policy.retryDelayIfActive(enabledForTarget: true) == 3)
        #expect(policy.retryDelayIfActive(enabledForTarget: false) == nil)
        // Waiting several cycles for a sleeping remote must not consume recovery.
        for _ in 0..<50 { #expect(policy.shouldDiscover) }
        policy.reset()
        #expect(policy.retryDelayIfActive(enabledForTarget: true) == nil)
        let sleptAgain = policy.shouldDiscover
        #expect(!sleptAgain)
        #expect(RemoteSleepReconnectPolicy.discoveryWindow == 20)
    }

}
