//
//  ReentrantResolveTests.swift
//  SwiftiePod
//
//  Tests for re-entrant resolve behaviour (issue #4).
//
//  A provider builder that calls `pod.resolve()` on the *same* SwiftiePod
//  instance re-entrantly will deadlock because `SwiftiePod.resolve` uses
//  `dispatchQueue.sync` and GCD serial queues do not support re-entrancy.
//
//  The safe pattern is to use the `resolver` parameter passed into the builder
//  closure — that goes through `InternalProviderResolver` which never acquires
//  the queue.  The dangerous pattern occurs when code reachable from a builder
//  uses a captured / global `pod` reference directly (e.g. a `Log` shim).
//

import Foundation
import Testing
@testable import SwiftiePod

struct ReentrantResolveTests {

    // MARK: - Safe path (should always pass)

    /// Resolving a nested provider via the *passed-in* resolver (the correct
    /// pattern) must work without any issues.
    @Test("Nested resolve via passed-in resolver works correctly")
    func testNestedResolveViaPassedInResolver() {
        let pod = SwiftiePod()

        let innerProvider = Provider<String> { _ in "hello" }

        let outerProvider = Provider<String> { resolver in
            // Correct usage: use the resolver parameter, NOT pod directly.
            let inner = resolver.resolve(innerProvider)
            return "outer: \(inner)"
        }

        let result = pod.resolve(outerProvider)
        #expect(result == "outer: hello")
    }

    // MARK: - Re-entrant path (reproduces issue #4)

    /// Calling `pod.resolve()` on the **global** pod instance from *inside* a
    /// provider builder re-enters `dispatchQueue.sync` on the same serial queue,
    /// causing a deadlock / signal-trap crash.
    ///
    /// This test uses a background thread + semaphore with a timeout so that a
    /// deadlock causes a test *failure* rather than hanging the suite forever.
    ///
    /// Expected result once issue #4 is fixed: the resolve completes and
    /// returns `"outer: hello"`.
    @Test("Re-entrant resolve on same pod does not deadlock (issue #4)")
    func testReentrantResolveDoesNotDeadlock() {
        let pod = SwiftiePod()

        let innerProvider = Provider<String> { _ in "hello" }

        // This provider captures `pod` and calls `pod.resolve()` directly —
        // the same pattern as a legacy `Log` shim resolving from a global pod.
        let outerProvider = Provider<String> { _ in
            // ↓ Re-entrant: calls pod.resolve while the outer resolve lock is held.
            let inner = pod.resolve(innerProvider)
            return "outer: \(inner)"
        }

        let semaphore = DispatchSemaphore(value: 0)
        var resolvedValue: String?

        DispatchQueue.global().async {
            resolvedValue = pod.resolve(outerProvider)
            semaphore.signal()
        }

        // Allow up to 5 seconds. A deadlock will time out and fail the test
        // rather than hanging the entire test suite.
        let completed = semaphore.wait(timeout: .now() + 5)

        #expect(completed == .success, "pod.resolve deadlocked — re-entrant resolve was not handled (issue #4)")
        if completed == .success {
            #expect(resolvedValue == "outer: hello")
        }
    }

    // MARK: - Real-world scenario: Log shim re-entrancy

    /// Simulates the real-world scenario from issue #4 where a `Log`-style
    /// helper resolves a dependency from the global pod.  When the dependency
    /// being resolved encounters an error path that calls `Log.error(...)`, the
    /// nested `pod.resolve(loggerProvider)` deadlocks.
    @Test("Log-shim style re-entrant resolve does not deadlock (issue #4)")
    func testLogShimReentrancyDoesNotDeadlock() {
        let pod = SwiftiePod()

        // Simulate a logger resolved from the global pod by a Log shim.
        let loggerProvider = Provider<LoggerStub> { _ in LoggerStub() }

        // Simulate a service that calls Log.error() during its init, which
        // internally re-resolves `loggerProvider` from `pod`.
        let serviceProvider = Provider<ServiceStub> { _ in
            let logger = pod.resolve(loggerProvider) // ← re-entrant resolve
            return ServiceStub(logger: logger)
        }

        let semaphore = DispatchSemaphore(value: 0)
        var service: ServiceStub?

        DispatchQueue.global().async {
            service = pod.resolve(serviceProvider)
            semaphore.signal()
        }

        let completed = semaphore.wait(timeout: .now() + 5)

        #expect(completed == .success, "pod.resolve deadlocked in Log-shim scenario (issue #4)")
        if completed == .success {
            #expect(service != nil)
            #expect(service?.logger != nil)
        }
    }
}

    // MARK: - Self-referential re-entrant cycle (issue #5)

    /// A provider whose builder calls `pod.resolve()` on **itself** (via a
    /// direct pod reference) must be detected as a cyclic dependency and call
    /// `cyclicDependencyHandler` rather than looping forever.
    ///
    /// Uses the same thread-blocking pattern as the existing cyclic dependency
    /// test to prevent the resolve thread from continuing after the handler fires.
    @Test("Re-entrant self-cycle via direct pod reference calls cyclic dependency handler (issue #5)")
    func testReentrantSelfCycleIsDetected() {
        let pod = SwiftiePod()

        let detectedCycle = ThreadSafeResults<String>()
        let detected = DispatchSemaphore(value: 0)

        let originalHandler = cyclicDependencyHandler
        cyclicDependencyHandler = { message in
            detectedCycle.append(message)
            detected.signal()
            // Block the thread so execution does not fall through after detection.
            repeat { Thread.sleep(forTimeInterval: 86400) } while true
        }

        // The provider captures itself and calls pod.resolve() on itself directly.
        var selfRefProvider: Provider<String>?
        selfRefProvider = Provider<String> { _ in
            pod.resolve(selfRefProvider!)  // ← re-entrant self-cycle
        }

        let resolveThread = Thread {
            _ = pod.resolve(selfRefProvider!)
        }
        resolveThread.start()

        detected.wait()
        cyclicDependencyHandler = originalHandler

        #expect(detectedCycle.values.count == 1)
        #expect(detectedCycle.values.first?.contains("Re-entrant cyclic dependency detected") == true)
    }

// MARK: - Test helpers

private final class LoggerStub {
    func error(_ message: String) { /* no-op */ }
}

private final class ServiceStub {
    let logger: LoggerStub
    init(logger: LoggerStub) { self.logger = logger }
}
