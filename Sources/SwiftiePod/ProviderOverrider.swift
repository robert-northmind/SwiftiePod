//
//  ProviderOverrider.swift
//  SwiftiePod
//
//  Created by Robert Magnusson on 11.12.24.
//

import Foundation

final class ProviderOverrider: @unchecked Sendable {
    init(instanceContainer: ProviderInstanceContainer) {
        self.instanceContainer = instanceContainer
    }

    private let dispatchQueue = DispatchQueue(label: "provider.overrider.lock.queue")
    
    private var originalToOverrideProviderDict = [AnyProvider: AnyProvider]()
    private var instanceContainer: ProviderInstanceContainer

    func getOverriddenAnyProvider<T>(_ provider: Provider<T>) -> AnyProvider? {
        let overrideAnyProvider = dispatchQueue.sync {
            let anyProvider = AnyProvider(provider)
            return originalToOverrideProviderDict[anyProvider]
        }
        return overrideAnyProvider
    }

    func getOverriddenProviderInstance<T>(_ provider: Provider<T>) -> Any? {
        guard let overriddenAnyProvider = getOverriddenAnyProvider(provider) else { return nil }

        let overriddenInstance = dispatchQueue.sync {
            return instanceContainer.get(overriddenAnyProvider)
        }
        return overriddenInstance
    }

    func setOverrideInstance<T>(_ provider: Provider<T>, _ newInstance: T) {
        guard let overriddenAnyProvider = getOverriddenAnyProvider(provider) else { return }

        dispatchQueue.sync {
            instanceContainer.set(overriddenAnyProvider, newInstance)
        }
    }

    func isProviderOverridden<T>(_ provider: Provider<T>) -> Bool {
        let isOverridden = dispatchQueue.sync {
            let anyProvider = AnyProvider(provider)
            return originalToOverrideProviderDict[anyProvider] != nil
        }
        return isOverridden
    }
    
    func removeOverride<T>(forProvider provider: Provider<T>) {
        guard let overriddenAnyProvider = getOverriddenAnyProvider(provider) else { return }

        dispatchQueue.sync {
            instanceContainer.remove(overriddenAnyProvider)
            let anyProvider = AnyProvider(provider)
            originalToOverrideProviderDict.removeValue(forKey: anyProvider)
        }
    }
    
    func overrideProvider<T>(
        _ provider: Provider<T>,
        with builder: @escaping (ProviderResolver) -> T,
        scope: ProviderScope? = nil
    ) {
        dispatchQueue.sync {
            let anyProvider = AnyProvider(provider)
            let overrideAnyProvider = AnyProvider(
                Provider(scope: scope ?? provider.scope, builder)
            )

            instanceContainer.remove(overrideAnyProvider)
            originalToOverrideProviderDict[anyProvider] = overrideAnyProvider
        }
    }

    func clearInstances(forScope scope: ProviderScope) {
        dispatchQueue.sync {
            instanceContainer.clearAllInstances(forScope: scope)
        }
    }
}
