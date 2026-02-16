//
//  ExampleIosAppTests.swift
//  ExampleIosAppTests
//
//  Created by Robert Magnusson on 16.02.26.
//

import Testing
import SwiftiePod
@testable import ExampleIosApp

// These classes are implicitly @MainActor because the test target has
// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor (matching the app target).
// This validates that Provider works correctly in this environment.

class ImplicitMainActorService {
    let value: String
    init(value: String = "default") {
        self.value = value
    }
}

class ImplicitMainActorServiceWithDependency {
    let dependency: ImplicitMainActorService
    init(dependency: ImplicitMainActorService) {
        self.dependency = dependency
    }
}

// Explicitly nonisolated class — should also work with Provider
nonisolated class NonisolatedService {
    let value: Int
    nonisolated init(value: Int = 42) {
        self.value = value
    }
}

// Top-level providers (recommended pattern)
let implicitMainActorProvider = Provider { _ in
    return ImplicitMainActorService()
}

let implicitMainActorWithValueProvider = Provider { _ in
    return ImplicitMainActorService(value: "custom")
}

let dependencyChainProvider = Provider { pod in
    return ImplicitMainActorServiceWithDependency(
        dependency: pod.resolve(implicitMainActorProvider)
    )
}

let nonisolatedProvider = Provider { _ in
    return NonisolatedService()
}

let nonisolatedWithValueProvider = Provider { _ in
    return NonisolatedService(value: 99)
}

// Protocol-typed provider
protocol AppServiceProtocol {
    var serviceName: String { get }
}

class AppServiceImpl: AppServiceProtocol {
    let serviceName = "AppService"
}

let appServiceProvider = Provider<AppServiceProtocol> { _ in
    return AppServiceImpl()
}

struct ExampleIosAppTests {

    // MARK: - Implicitly @MainActor class tests

    @Test("Provider resolves implicitly MainActor class without warnings")
    func testImplicitMainActorProvider() {
        let pod = SwiftiePod()
        let service = pod.resolve(implicitMainActorProvider)
        #expect(service.value == "default")
    }

    @Test("Provider resolves implicitly MainActor class with custom value")
    func testImplicitMainActorWithValue() {
        let pod = SwiftiePod()
        let service = pod.resolve(implicitMainActorWithValueProvider)
        #expect(service.value == "custom")
    }

    @Test("Provider caches singleton for implicitly MainActor class")
    func testImplicitMainActorSingleton() {
        let pod = SwiftiePod()
        let service1 = pod.resolve(implicitMainActorProvider)
        let service2 = pod.resolve(implicitMainActorProvider)
        #expect(service1 === service2)
    }

    // MARK: - Nonisolated class tests

    @Test("Provider resolves nonisolated class without warnings")
    func testNonisolatedProvider() {
        let pod = SwiftiePod()
        let service = pod.resolve(nonisolatedProvider)
        #expect(service.value == 42)
    }

    @Test("Provider resolves nonisolated class with custom value")
    func testNonisolatedWithValue() {
        let pod = SwiftiePod()
        let service = pod.resolve(nonisolatedWithValueProvider)
        #expect(service.value == 99)
    }

    // MARK: - Dependency chain tests

    @Test("Dependency chain with implicitly MainActor classes resolves correctly")
    func testDependencyChain() {
        let pod = SwiftiePod()
        let service = pod.resolve(dependencyChainProvider)
        #expect(service.dependency.value == "default")
    }

    @Test("Dependency chain uses same singleton for shared dependency")
    func testDependencyChainSingleton() {
        let pod = SwiftiePod()
        let service = pod.resolve(dependencyChainProvider)
        let directDep = pod.resolve(implicitMainActorProvider)
        #expect(service.dependency === directDep)
    }

    // MARK: - Protocol-typed provider tests

    @Test("Protocol-typed provider resolves correctly")
    func testProtocolProvider() {
        let pod = SwiftiePod()
        let service = pod.resolve(appServiceProvider)
        #expect(service.serviceName == "AppService")
    }

    // MARK: - Override tests

    @Test("Override works with implicitly MainActor class")
    func testOverrideImplicitMainActor() {
        let pod = SwiftiePod()

        let original = pod.resolve(implicitMainActorProvider)
        #expect(original.value == "default")

        pod.overrideProvider(implicitMainActorProvider) { _ in
            return ImplicitMainActorService(value: "overridden")
        }

        let overridden = pod.resolve(implicitMainActorProvider)
        #expect(overridden.value == "overridden")
    }

    @Test("Remove override restores original behavior")
    func testRemoveOverride() {
        let pod = SwiftiePod()

        pod.overrideProvider(implicitMainActorProvider) { _ in
            return ImplicitMainActorService(value: "mock")
        }
        let mocked = pod.resolve(implicitMainActorProvider)
        #expect(mocked.value == "mock")

        pod.removeOverrideProvider(implicitMainActorProvider)
        let restored = pod.resolve(implicitMainActorProvider)
        #expect(restored.value == "default")
    }

    // MARK: - Mixed isolation tests

    @Test("Pod can resolve both MainActor and nonisolated providers")
    func testMixedIsolation() {
        let pod = SwiftiePod()
        let mainActorService = pod.resolve(implicitMainActorProvider)
        let nonisolatedService = pod.resolve(nonisolatedProvider)

        #expect(mainActorService.value == "default")
        #expect(nonisolatedService.value == 42)
    }

    // MARK: - App providers test (from ContentView.swift)

    @Test("App-defined providers from ContentView resolve correctly")
    func testAppProviders() {
        let pod = SwiftiePod()
        let myService = pod.resolve(myServiceProvider)
        let backgroundService = pod.resolve(backgroundServiceProvider)

        #expect(myService is MyService)
        #expect(backgroundService is BackgroundService)
    }
}
