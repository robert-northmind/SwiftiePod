//
//  SwiftiePod.swift
//  SwiftiePod
//
//  Created by Robert Magnusson on 17.10.24.
//

import Foundation

/// The pod/container which you use to get get instances from your providers.
///
/// Create an instance of a `SwiftiePod` once in your application  and then use this throughout your application to get instances.
///
/// ```
/// // Somewhere in the start up phase of your application
/// let pod = SwiftiePod()
/// ...
/// // Later in your application logic when you need an instance
/// let someInstance = pod.resolve(someInstanceProvider)
/// ```
///
/// Also use the SwiftiePod instance to control overrides of provider and caching of instances.
public final class SwiftiePod: ProviderResolver, @unchecked Sendable {
    public init() {
        self.providerOverrider = ProviderOverrider(instanceContainer: ProviderInstanceContainer())
        // Mark this queue so we can detect re-entrant calls from within a builder.
        dispatchQueue.setSpecific(key: queueKey, value: true)
    }

    private let dispatchQueue = DispatchQueue(label: "SwiftiePod.resolve.lock.queue")
    // Used to detect whether the current execution context is already inside the queue.
    private let queueKey = DispatchSpecificKey<Bool>()

    private let instanceContainer = ProviderInstanceContainer()
    private let providerOverrider: ProviderOverrider
    // Tracks providers whose builder is actively on the call stack, so that
    // re-entrant calls to pod.resolve() on the same provider can be detected
    // as self-referential cycles rather than silently recursing forever.
    private var currentlyBuildingProviders = Set<ObjectIdentifier>()

    /// Resolves a provider to its associated instance.
    ///
    /// This method resolves the provided `Provider<T>` instance.
    /// If the provider has an override, it will use the override.
    ///
    /// If the provider has scope which is `AlwaysCreateNewScope` then a new instance will
    /// always be created. For all other scopes, the instance will be created once, and then cached.
    /// It is possible to clear the cache by calling `clearCachedInstances`
    ///
    /// - Parameter provider: The provider to resolve.
    /// - Returns: The instance associated with the given provider.
    ///
    /// - Note: The preferred way to resolve nested dependencies is to use the `ProviderResolver`
    ///   parameter that is passed into a provider's builder closure. Calling `pod.resolve()` on
    ///   this `SwiftiePod` instance from within a builder closure (e.g. via a global reference)
    ///   is also supported — the container detects re-entrant calls and avoids deadlocking.
    public func resolve<T>(_ originalProvider: Provider<T>) -> T {
        // If we are already executing on the queue (re-entrant call from within a builder
        // that references this pod directly), skip the `sync` to prevent a deadlock.
        if DispatchQueue.getSpecific(key: queueKey) == true {
            // Detect a self-referential cycle: the same provider's builder is already
            // on the call stack and has called pod.resolve() on itself.
            if currentlyBuildingProviders.contains(ObjectIdentifier(originalProvider)) {
                let anyProvider = AnyProvider(originalProvider)
                cyclicDependencyHandler("\nRe-entrant cyclic dependency detected. \(anyProvider) tried to resolve itself via a direct pod reference.")
            }
            return makeInternalResolver().resolve(originalProvider)
        }
        return dispatchQueue.sync {
            makeInternalResolver().resolve(originalProvider)
        }
    }

    private func makeInternalResolver() -> InternalProviderResolver {
        InternalProviderResolver(
            instanceContainer: instanceContainer,
            processingAnyProviders: ProcessingAnyProviders.getInitial(),
            providerOverrider: providerOverrider,
            onBuildStart: { [self] id in currentlyBuildingProviders.insert(id) },
            onBuildEnd: { [self] id in currentlyBuildingProviders.remove(id) }
        )
    }

    /// Overrides an existing provider with a custom builder so that you can change how to return an instance of that providers type.
    ///
    /// This allows dynamically overriding the behavior of a provider, which might be useful
    /// during testing, or during a specific sub-flow of your application.
    ///
    /// The override can optionally have a different scope than the provider it overrides.
    /// This means that your override e.g. could have `AlwaysCreateNewScope` but the
    /// original provider which it overrides might have `SingletonScope`.
    ///
    /// - Parameters:
    ///   - provider: The provider to override.
    ///   - builder: A closure that builds the instance for the override.
    ///   - scope: The scope within which the override is applied. Defaults to `nil`, meaning it will use the same scope as the provider it overrides.
    public func overrideProvider<T>(
        _ provider: Provider<T>,
        with builder: @escaping (ProviderResolver) -> T,
        scope: ProviderScope? = nil
    ) {
        dispatchQueue.sync {
            providerOverrider.overrideProvider(provider, with: builder, scope: scope)
        }
    }

    /// Removes an override for a provider.
    ///
    /// This method removes any custom behavior previously defined for the given provider.
    ///
    /// - Parameter provider: The provider whose override should be removed.
    public func removeOverrideProvider<T>(_ provider: Provider<T>) {
        dispatchQueue.sync {
            providerOverrider.removeOverride(forProvider: provider)
        }
    }

    /// Clears cached instances for a given scope.
    ///
    /// This method removes all cached instances within the specified scope,
    /// ensuring that new instances will be created for future resolutions.
    ///
    /// This method also clears all cached instances of any child scopes of the provided scope.
    ///
    /// Note: Instances with `SingletonScope` will never be cleared from the cache.
    ///
    /// - Parameter scope: The scope for which to clear cached instances.
    public func clearCachedInstances(forScope scope: ProviderScope) {
        dispatchQueue.sync {
            instanceContainer.clearAllInstances(forScope: scope)
            providerOverrider.clearInstances(forScope: scope)
        }
    }
}
