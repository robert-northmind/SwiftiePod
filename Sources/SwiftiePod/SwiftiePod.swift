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
    }

    private let dispatchQueue = DispatchQueue(label: "SwiftiePod.resolve.lock.queue")

    private let instanceContainer = ProviderInstanceContainer()
    private let providerOverrider: ProviderOverrider

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
    public func resolve<T>(_ originalProvider: Provider<T>) -> T {
        let theInstance = dispatchQueue.sync {
            let internalProviderResolver = InternalProviderResolver(
                instanceContainer: instanceContainer,
                processingAnyProviders: ProcessingAnyProviders.getInitial(),
                providerOverrider: providerOverrider
            )
            return internalProviderResolver.resolve(originalProvider)
        }
        return theInstance
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
