//
//  Provider.swift
//  SwiftPod
//
//  Created by Robert Magnusson on 17.10.24.
//

class Provider<T>: Hashable {
    init(scope: ProviderScope = .singleton, _ builder: @escaping (SwiftPod) -> T) {
        self.builder = builder
        self.scope = scope
    }

    private let builder: (SwiftPod) -> T
    let scope: ProviderScope

    func build(_ pod: SwiftPod) -> T {
        return builder(pod)
    }

    static func == (lhs: Provider<T>, rhs: Provider<T>) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
