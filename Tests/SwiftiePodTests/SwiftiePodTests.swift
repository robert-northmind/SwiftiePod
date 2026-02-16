//
//  ProviderScopeTests.swift
//  SwiftiePod
//
//  Created by Robert Magnusson on 21.10.24.
//

import Foundation
import Testing
@testable import SwiftiePod

struct SwiftiePodTests {
    init() {
      pod = SwiftiePod()
    }
    
    var pod: SwiftiePod

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
    func testConcurrentResolveSingleton() async {
        let iterations = 40
        let results = ThreadSafeResults<String>()

        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "concurrentQueue", attributes: .concurrent)

        for _ in 0..<iterations {
            dispatchGroup.enter()
            queue.async {
                let randomIntAsString = pod.resolve(randomIntAsStringProvider)
                results.append(randomIntAsString)
                dispatchGroup.leave()
            }
        }
        await dispatchGroup.waitForCompletion()
        let uniqueValues = Set(results.values)
        #expect(uniqueValues.count == 1)
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

        pod.clearCachedInstances(forScope: CustomParentScope())
        
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

        pod.clearCachedInstances(forScope: CustomChildScope())
        
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

        pod.clearCachedInstances(forScope: CustomParentScope())
        
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
        
        pod.clearCachedInstances(forScope: CustomParentScope())
        
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
        
        pod.clearCachedInstances(forScope: CustomParentScope())
        
        let overriddenInstance3 = pod.resolve(testCustomParentScopeProvider)
        #expect(overriddenInstance3 is SubTestClass)
        #expect(overriddenInstance1 === overriddenInstance3)
        
        pod.clearCachedInstances(forScope: CustomOtherScope())
        
        let overriddenInstance4 = pod.resolve(testCustomParentScopeProvider)
        #expect(overriddenInstance3 is SubTestClass)
        #expect(overriddenInstance1 !== overriddenInstance4)
    }
    
    @Test("Clear instances for SingletonScope does not remove the instances")
    func testClearInstancesForSingletonDoesNotRemoveInstances() {
        let result1 = pod.resolve(randomIntAsStringProvider)
        let result2 = pod.resolve(randomIntAsStringProvider)

        #expect(result1 == result2)

        pod.clearCachedInstances(forScope: SingletonScope())

        let result3 = pod.resolve(randomIntAsStringProvider)

        #expect(result1 == result3)
    }

    @Test("Cyclic dependency fails", .disabled("Cyclic check calls fatalError, which cannot be tested"))
    func testCyclicProviders() {
        _ = pod.resolve(cyclicProvider)
    }

    // MARK: - Dependency chain tests

    @Test("Provider with dependency chain resolves correctly")
    func testDependencyChainResolution() {
        let result = pod.resolve(serviceWithDependencyProvider)
        #expect(result.dependency.name == "ConcreteService")
    }

    @Test("Protocol-typed provider resolves to concrete type")
    func testProtocolTypedProvider() {
        let result = pod.resolve(serviceProvider)
        #expect(result.name == "ConcreteService")
        #expect(result is ConcreteService)
    }

    @Test("Dependency chain returns same singleton instances")
    func testDependencyChainSingleton() {
        let result1 = pod.resolve(serviceWithDependencyProvider)
        let result2 = pod.resolve(serviceWithDependencyProvider)
        // Both resolves should return the same cached instance
        #expect(result1 === result2)
        // The dependency should also be the same singleton
        #expect(result1.dependency as AnyObject === result2.dependency as AnyObject)
    }

    // MARK: - Override without @Sendable tests

    @Test("Override provider works with closure capturing local mutable state")
    func testOverrideWithNonSendableClosure() {
        var callCount = 0
        pod.overrideProvider(testAlwaysNewProvider) { _ in
            callCount += 1
            return SubTestClass()
        }

        _ = pod.resolve(testAlwaysNewProvider)
        _ = pod.resolve(testAlwaysNewProvider)
        _ = pod.resolve(testAlwaysNewProvider)

        #expect(callCount == 3)
    }

    @Test("Override provider with dependency chain works")
    func testOverrideWithDependencyChain() {
        pod.overrideProvider(serviceProvider) { _ in
            return ConcreteService(name: "MockService")
        }

        let result = pod.resolve(serviceWithDependencyProvider)
        // The dependency should use the overridden provider
        #expect(result.dependency.name == "MockService")
    }

    // MARK: - Concurrent resolve + override tests

    @Test("Concurrent resolves with override produce consistent results")
    func testConcurrentResolveWithOverride() async {
        pod.overrideProvider(fixedIntProvider) { _ in
            return 999
        }

        let iterations = 40
        let results = ThreadSafeResults<Int>()
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "concurrentOverrideQueue", attributes: .concurrent)

        for _ in 0..<iterations {
            dispatchGroup.enter()
            queue.async {
                let value = pod.resolve(fixedIntProvider)
                results.append(value)
                dispatchGroup.leave()
            }
        }
        await dispatchGroup.waitForCompletion()

        // All results should be the overridden value
        for value in results.values {
            #expect(value == 999)
        }
    }

    // MARK: - Concurrent clearAllInstances tests

    @Test("Concurrent resolves during cache clearing do not crash")
    func testConcurrentResolveWithCacheClear() async {
        let iterations = 40
        let results = ThreadSafeResults<Bool>()
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "concurrentClearQueue", attributes: .concurrent)

        for i in 0..<iterations {
            dispatchGroup.enter()
            queue.async {
                if i % 5 == 0 {
                    // Every 5th iteration, clear the cache
                    pod.clearCachedInstances(forScope: CustomParentScope())
                }
                // Always resolve
                _ = pod.resolve(testCustomParentScopeProvider)
                results.append(true)
                dispatchGroup.leave()
            }
        }
        await dispatchGroup.waitForCompletion()

        // All results should have successfully resolved to TestClass
        for value in results.values {
            #expect(value == true)
        }
        #expect(results.values.count == iterations)
    }

    // MARK: - Provider with value types

    @Test("Provider with Int value type resolves correctly")
    func testIntProvider() {
        let result = pod.resolve(fixedIntProvider)
        #expect(result == 123)
    }

    @Test("Provider with String dependency chain resolves correctly")
    func testStringDependencyChain() {
        let result = pod.resolve(fixedIntAsStringProvider)
        #expect(result == "123")
    }
}
