//
//  ProviderInstanceContainer.swift
//  SwiftiePod
//
//  Created by Robert Magnusson on 11.12.24.
//

import Foundation

final class ProviderInstanceContainer: @unchecked Sendable {
    private let dispatchQueue = DispatchQueue(label: "instance.container.lock.queue")

    private var scopeProvidersDict: [ObjectIdentifier: [AnyProvider: Any]] = [:]

    func get(_ anyProvider: AnyProvider) -> Any? {
        let instance = dispatchQueue.sync {
            let instanceDict = getScopeInstanceDict(anyProvider)
            return instanceDict[anyProvider]
        }
        return instance
    }

    func set<T>(_ anyProvider: AnyProvider, _ newInstance: T) {
        dispatchQueue.sync {
            var instanceDict = getScopeInstanceDict(anyProvider)
            instanceDict[anyProvider] = newInstance
            setScopeInstanceDict(anyProvider, newInstanceDict: instanceDict)
        }
    }

    func remove(_ anyProvider: AnyProvider) {
        dispatchQueue.sync {
            var instanceDict = getScopeInstanceDict(anyProvider)
            _ = instanceDict.removeValue(forKey: anyProvider)
            setScopeInstanceDict(anyProvider, newInstanceDict: instanceDict)
        }
    }

    func clearAllInstances(forScope scope: any ProviderScope) {
        dispatchQueue.sync {
            var scopes: [any ProviderScope] = [scope]
            var visitedScopes: Set<ObjectIdentifier> = []

            while !scopes.isEmpty {
                let currentScope = scopes.removeFirst()
                let currentScopeIdentifier = ObjectIdentifier(type(of: currentScope))

                let isSingleTonScope = currentScope is SingletonScope
                if !isSingleTonScope {
                    _ = scopeProvidersDict.removeValue(forKey: currentScopeIdentifier)
                }

                visitedScopes.insert(currentScopeIdentifier)

                for childScope in currentScope.children {
                    let childScopeIdentifier = ObjectIdentifier(type(of: childScope))
                    if !visitedScopes.contains(childScopeIdentifier) {
                        scopes.append(childScope)
                    }
                }
            }
        }
    }
    
    private func getScopeInstanceDict(_ anyProvider: AnyProvider) -> [AnyProvider: Any] {
        let scopeIdentifier = ObjectIdentifier(type(of: anyProvider.scope))
        return scopeProvidersDict[scopeIdentifier] ?? [:]
    }
    
    private func setScopeInstanceDict(_ anyProvider: AnyProvider, newInstanceDict: [AnyProvider: Any]) {
        let scopeIdentifier = ObjectIdentifier(type(of: anyProvider.scope))
        scopeProvidersDict[scopeIdentifier] = newInstanceDict
    }
}
