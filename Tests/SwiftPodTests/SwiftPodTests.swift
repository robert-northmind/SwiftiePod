//
//  ProviderScopeTests.swift
//  SwiftPod
//
//  Created by Robert Magnusson on 21.10.24.
//

import Foundation
import Testing
@testable import SwiftPod

struct SwiftPodTests {
    init() {
      pod = SwiftPod()
    }
    
    var pod: SwiftPod

    @Test("AlwaysCreateNewScope always creates a new instance")
    func testWithAlwaysCreateNewScope() async throws {
        let instance = pod.resolve(testAlwaysNewProvider)
        let instance2 = pod.resolve(testAlwaysNewProvider)
        let instance3 = pod.resolve(testAlwaysNewProvider)
        
        #expect(instance !== instance2)
        #expect(instance !== instance3)
        #expect(instance2 !== instance3)
    }
    
    @Test("NoScope always uses the same instance")
    func testProviderWithNoScope() async throws {
        let instance = pod.resolve(testStaticProvider)
        let instance2 = pod.resolve(testStaticProvider)
        let instance3 = pod.resolve(testStaticProvider)
        
        #expect(instance === instance2)
        #expect(instance === instance3)
    }
    
    @Test("OverrideProvider overrides the provider with no caching")
    func testOverrideProviderNoCaching() async throws {
        let initialInstance = pod.resolve(testAlwaysNewProvider)
        #expect(initialInstance is SubTestClass == false)

        pod.overrideProvider(testAlwaysNewProvider) { _ in
            return SubTestClass()
        }

        let overriddenInstance = pod.resolve(testAlwaysNewProvider)
        #expect(overriddenInstance is SubTestClass)
    }
    
    @Test("OverrideProvider overrides the provider with caching")
    func testOverrideProviderWithCaching() async throws {
        let initialInstance = pod.resolve(testStaticProvider)
        #expect(initialInstance is SubTestClass == false)

        pod.overrideProvider(testStaticProvider) { _ in
            return SubTestClass()
        }

        let overriddenInstance = pod.resolve(testStaticProvider)
        #expect(overriddenInstance is SubTestClass)
    }
    
    @Test("OverrideProvider overrides the provider with caching and returns cached instance")
    func testOverrideProviderWithCachingAndCachedInstance() async throws {
        pod.overrideProvider(testStaticProvider) { _ in
            return SubTestClass()
        }

        let overriddenInstance1 = pod.resolve(testStaticProvider)
        #expect(overriddenInstance1 is SubTestClass)
        
        let overriddenInstance2 = pod.resolve(testStaticProvider)
        #expect(overriddenInstance1 === overriddenInstance2)
    }
    
    @Test("RemoveOverrideProvider removes any overridden provider")
    func testRemoveOverrideProvider() async throws {
        pod.overrideProvider(testAlwaysNewProvider) { _ in
            return SubTestClass()
        }

        let overriddenInstance = pod.resolve(testAlwaysNewProvider)
        #expect(overriddenInstance is SubTestClass)

        pod.removeOverrideProvider(testAlwaysNewProvider)

        let nonOverriddenInstance = pod.resolve(testAlwaysNewProvider)
        #expect(nonOverriddenInstance is SubTestClass == false)
    }
    
    @Test("OverrideProvider uses same scope as provider when no scope provided")
    func testOverrideProviderWithNoScope() async throws {
        pod.overrideProvider(testAlwaysNewProvider) { _ in
            return SubTestClass()
        }

        let overriddenInstance1 = pod.resolve(testAlwaysNewProvider)
        let overriddenInstance2 = pod.resolve(testAlwaysNewProvider)

        #expect(overriddenInstance1 is SubTestClass)
        #expect(overriddenInstance2 is SubTestClass)
        #expect(overriddenInstance1 !== overriddenInstance2)
    }
    
    @Test("OverrideProvider uses passed in scope when provided")
    func testOverrideProviderWithCustomScope() async throws {
        pod.overrideProvider(
            testAlwaysNewProvider,
            with: { _ in
                return SubTestClass()
            },
            scope: SingletonScope()
        )

        let overriddenInstance1 = pod.resolve(testAlwaysNewProvider)
        let overriddenInstance2 = pod.resolve(testAlwaysNewProvider)

        #expect(overriddenInstance1 is SubTestClass)
        #expect(overriddenInstance2 is SubTestClass)
        #expect(overriddenInstance1 === overriddenInstance2)
    }
    
    @Test("Can handle concurrency. Random int provider should always produce same value for all tasks")
    func testDependencyCycles() async {
        let iterations = 40

        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "concurrentQueue", attributes: .concurrent)
        var resultSet = Set<String>()
        
        for _ in 0..<iterations {
            dispatchGroup.enter()
            queue.async {
                Task {
                    let randomIntAsString = pod.resolve(randomIntAsStringProvider)
                    await MainActor.run(body: {
                        resultSet.insert(randomIntAsString)
                        dispatchGroup.leave()
                    })
                }
            }
        }
        await dispatchGroup.waitForCompletion()
        #expect(resultSet.count == 1)
    }
    
    @Test("Clear instances for scope removes all cached instances for that scope")
    func testClearInstancesRemovesForScope() {
        let parentInstance1 = pod.resolve(testCustomParentScopeProvider)
        let parentInstance2 = pod.resolve(testCustomParentScopeProvider)
        let childInstance1 = pod.resolve(testCustomChildScopeProvider)
        let childInstance2 = pod.resolve(testCustomChildScopeProvider)
        let grandChildInstance1 = pod.resolve(testCustomGrandChildScopeProvider)
        let grandChildInstance2 = pod.resolve(testCustomGrandChildScopeProvider)

        #expect(parentInstance1 !== childInstance1)
        #expect(parentInstance1 !== grandChildInstance1)
        #expect(parentInstance1 === parentInstance2)
        #expect(childInstance1 === childInstance2)
        #expect(grandChildInstance1 === grandChildInstance2)

        pod.clearInstances(forScope: CustomParentScope())
        
        let parentInstance3 = pod.resolve(testCustomParentScopeProvider)
        let childInstance3 = pod.resolve(testCustomChildScopeProvider)
        let grandChildInstance3 = pod.resolve(testCustomGrandChildScopeProvider)
        
        #expect(parentInstance3 !== childInstance3)
        #expect(parentInstance3 !== grandChildInstance3)
        #expect(parentInstance1 !== parentInstance3)
        #expect(childInstance1 !== childInstance3)
        #expect(grandChildInstance1 !== grandChildInstance3)
    }
    
    @Test("Clear instances for child scope only")
    func testClearInstancesForChildScopeOnly() {
        let parentInstance1 = pod.resolve(testCustomParentScopeProvider)
        let parentInstance2 = pod.resolve(testCustomParentScopeProvider)
        let childInstance1 = pod.resolve(testCustomChildScopeProvider)
        let childInstance2 = pod.resolve(testCustomChildScopeProvider)
        let grandChildInstance1 = pod.resolve(testCustomGrandChildScopeProvider)
        let grandChildInstance2 = pod.resolve(testCustomGrandChildScopeProvider)

        #expect(parentInstance1 !== childInstance1)
        #expect(parentInstance1 !== grandChildInstance1)
        #expect(parentInstance1 === parentInstance2)
        #expect(childInstance1 === childInstance2)
        #expect(grandChildInstance1 === grandChildInstance2)

        pod.clearInstances(forScope: CustomChildScope())
        
        let parentInstance3 = pod.resolve(testCustomParentScopeProvider)
        let childInstance3 = pod.resolve(testCustomChildScopeProvider)
        let grandChildInstance3 = pod.resolve(testCustomGrandChildScopeProvider)

        #expect(parentInstance3 !== childInstance3)
        #expect(parentInstance3 !== grandChildInstance3)
        #expect(parentInstance1 === parentInstance3)
        #expect(childInstance1 !== childInstance3)
        #expect(grandChildInstance1 !== grandChildInstance3)
    }
    
    @Test("Clear instances for scope does not remove instances with other scope")
    func testClearInstancesDoesNotRemoveForOtherScopes() {
        let parentInstance1 = pod.resolve(testCustomParentScopeProvider)
        let parentInstance2 = pod.resolve(testCustomParentScopeProvider)
        let otherInstance1 = pod.resolve(testCustomOtherScopeProvider)
        let otherInstance2 = pod.resolve(testCustomOtherScopeProvider)

        #expect(parentInstance1 !== otherInstance1)
        #expect(parentInstance1 === parentInstance2)
        #expect(otherInstance1 === otherInstance2)

        pod.clearInstances(forScope: CustomParentScope())
        
        let parentInstance3 = pod.resolve(testCustomParentScopeProvider)
        let otherInstance3 = pod.resolve(testCustomOtherScopeProvider)
        
        #expect(parentInstance3 !== otherInstance3)
        #expect(parentInstance1 !== parentInstance3)
        #expect(otherInstance1 === otherInstance3)
    }
    
    @Test("Clear instances for scope removes all cached instances for that scope also for overrides")
    func testClearInstancesRemovesOverridesAlsoForScope() {
        pod.overrideProvider(
            testCustomParentScopeProvider,
            with: { _ in
                return SubTestClass()
            }
        )

        let overriddenInstance1 = pod.resolve(testCustomParentScopeProvider)
        let overriddenInstance2 = pod.resolve(testCustomParentScopeProvider)

        #expect(overriddenInstance1 is SubTestClass)
        #expect(overriddenInstance2 is SubTestClass)
        #expect(overriddenInstance1 === overriddenInstance2)
        
        pod.clearInstances(forScope: CustomParentScope())
        
        let overriddenInstance3 = pod.resolve(testCustomParentScopeProvider)
        #expect(overriddenInstance3 is SubTestClass)
        #expect(overriddenInstance1 !== overriddenInstance3)
    }
    
    @Test("Clear instances for scope removes all cached instances for that scope also for overrides with custom scope")
    func testClearInstancesRemovesOverridesWithCustomScopeAlso() {
        pod.overrideProvider(
            testCustomParentScopeProvider,
            with: { _ in
                return SubTestClass()
            },
            scope: CustomOtherScope()
        )

        let overriddenInstance1 = pod.resolve(testCustomParentScopeProvider)
        let overriddenInstance2 = pod.resolve(testCustomParentScopeProvider)

        #expect(overriddenInstance1 is SubTestClass)
        #expect(overriddenInstance2 is SubTestClass)
        #expect(overriddenInstance1 === overriddenInstance2)
        
        pod.clearInstances(forScope: CustomParentScope())
        
        let overriddenInstance3 = pod.resolve(testCustomParentScopeProvider)
        #expect(overriddenInstance3 is SubTestClass)
        #expect(overriddenInstance1 === overriddenInstance3)
        
        pod.clearInstances(forScope: CustomOtherScope())
        
        let overriddenInstance4 = pod.resolve(testCustomParentScopeProvider)
        #expect(overriddenInstance3 is SubTestClass)
        #expect(overriddenInstance1 !== overriddenInstance4)
    }
 
    private class TestClass {}
    
    private class SubTestClass: TestClass {}

    private final class CustomParentScope: ProviderScope {
        let children: [any ProviderScope] = [CustomChildScope()]
    }

    private final class CustomChildScope: ProviderScope {
        let children: [any ProviderScope] = [CustomGrandChildScope()]
    }

    private final class CustomGrandChildScope: ProviderScope {
        let children: [any ProviderScope] = []
    }
    
    private final class CustomOtherScope: ProviderScope {
        let children: [any ProviderScope] = []
    }

    private let testAlwaysNewProvider = Provider(scope: AlwaysCreateNewScope()) { _ in
        return TestClass()
    }
    
    private let testStaticProvider = Provider { _ in
        return TestClass()
    }

    private let testCustomParentScopeProvider = Provider(scope: CustomParentScope()) { _ in
        return TestClass()
    }

    private let testCustomChildScopeProvider = Provider(scope: CustomChildScope()) { _ in
        return TestClass()
    }
    
    private let testCustomGrandChildScopeProvider = Provider(scope: CustomGrandChildScope()) { _ in
        return TestClass()
    }
    
    private let testCustomOtherScopeProvider = Provider(scope: CustomOtherScope()) { _ in
        return TestClass()
    }
}

// Helpers

let randomIntAsStringProvider = Provider<String>({ pod in
    let theInt = pod.resolve(randomIntProvider)
    return "\(theInt)"
})

let randomIntProvider = Provider<Int>({ _ in
    return (Int.random(in: 0..<100))
})

extension DispatchGroup {
    func waitForCompletion() async {
        await withCheckedContinuation { continuation in
            self.notify(queue: .main) {
                continuation.resume()
            }
        }
    }
}
