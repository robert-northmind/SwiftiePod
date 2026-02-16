//
//  Provider.swift
//  SwiftiePod
//
//  Created by Robert Magnusson on 17.10.24.
//

/// Use the `Provider` to define how to create instances for your types.
///
/// The `Provider` is sort of a builder method for your type.
/// In other DI frameworks you typically get an instance by passing in a type to some container.
/// This has the risk of runtime exceptions if that type was not registered before.
/// But this provider approach eliminates these runtime exceptions, since you use the provider to get the instance,
/// and the provider always knows how to build the instance.
///
/// You create one provider for each type which you need, and then you use that
/// provider to get an instance of that type.
/// E.g.:
///
/// ```
/// let myServiceProvider = Provider { _ in
///     return MyService()
/// }
/// ```
///
/// Then you pass this provider into the `SwiftiePod` to get an instance
///
/// ```
/// let myService = pod.resolve(myServiceProvider)
/// ```
///
/// If the instance creation of your type needs other types as input parameters,
/// then you can grab the instances from those types from the pod passed into the builder method of the `Provider`
///
/// ```
/// let myOtherServiceProvider = Provider { pod in
///     return MyOtherService(
///         myService: pod.resolve(myServiceProvider)
///     )
/// }
/// ```
///
/// You can also just define simple business logic or fixed primitive types using `Provider`.
/// E.g. you might define an app name like this:
///
/// ```
/// let myAppNameProvider = Provider { _ in
///     return "My cool app"
/// }
/// ```
///
/// Each provider has a `ProviderScope`. You can this scope parameters to control how the instances for your types are cached.
/// By default, when no scope is provided, the scope will be `SingletonScope` which means
/// that the instance is cached throughout the lifetime of your application.
/// But you can also use `AlwaysCreateNewScope` to make sure a new instance is always created.
/// You can even define your own custom scopes.
public final class Provider<T>: Hashable, @unchecked Sendable {
    public init(
        scope: ProviderScope = SingletonScope(),
        _ builder: @escaping (ProviderResolver) -> T
    ) {
        self.builder = builder
        self.scope = scope
    }

    private let builder: (ProviderResolver) -> T
    let scope: ProviderScope

    func build(_ providerResolver: ProviderResolver) -> T {
        return builder(providerResolver)
    }

    public static func == (lhs: Provider<T>, rhs: Provider<T>) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
