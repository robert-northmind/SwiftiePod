# SwiftiePod

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Frobert-northmind%2FSwiftiePod%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/robert-northmind/SwiftiePod)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Frobert-northmind%2FSwiftiePod%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/robert-northmind/SwiftiePod)

**SwiftiePod** is a lightweight and easy-to-use Dependency Injection (DI) library for Swift. It’s designed to be straightforward, efficient, and **most importantly** safe!

Unlike many other DI libraries, SwiftiePod ensures you won’t ever run into a runtime exception for forgetting to register a dependency before trying to resolve it.

### Why SwiftiePod?

- **Lightweight & Easy:** SwiftiePod does exactly what you need without unnecessary complexity. Setup and usage are kept simple and intuitive.
- **Compile-time Safety:** With SwiftiePod, you’ll never get a runtime exception for resolving an unregistered type. SwiftiePod’s approach helps you catch issues early, preventing nasty surprises at runtime.
- **Flexible State Management:** SwiftiePod can cache your instances if you want, making it easy to manage singletons or reuse existing objects when appropriate.

## Installation

### Swift Package Manager (SPM)

Add SwiftiePod as a dependency in your Package.swift:

```
dependencies: [
    .package(url: "https://github.com/robert-northmind/SwiftiePod.git", from: "1.0.8")
]
```

### CocoaPods

Add this to your Podfile:

```
pod 'SwiftiePod'
```

## Quick Example

In some made up business logic called `DataService.swift`:

```swift
import SwiftiePod

// Define a `Provider` for the `DataService`.
// A `Provider` is a SwiftiePod thing.
// It's a thing which knows how to build your types.
let dataServiceProvider = Provider<DataService> { pod in
    return RemoteDataService(
        httpClient: pod.resolve(httpClientProvider)
    )
}

protocol DataService {
    func fetchData() -> [String]
}

class RemoteDataService: DataService {
    private let httpClient: HttpClient

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func fetchData() async throws -> [String] {
        return await httpClient.get("/some/endpoint")
    }
}
```

In the start code of your app, you setup your pod:

```swift
import SwiftiePod
let pod = SwiftiePod()
```

Finally, when you need an instance of your `DataService` you resolve it from the pod:

```swift
import SwiftiePod
let dataService = pod.resolve(dataServiceProvider)
// Now you can use the dataService...
```

For more in-depth examples, see the [iOS Example App](Examples/ExampleIosApp/).

## Documentation

### Background

Most dependency injection libraries consists of some container, into which you register some builder for a given type. Something like this:

```swift
// Setup and register stuff
let container = DIContainer()
container.register(DataService.self) { _ in
    return RemoteDataService()
}

// Get your instance out of the container by passing the type
let dataService = container.resolve(DataService.self)!
```

This approach has some downsides:

- Risk of crashing your app. What happens if you try to resolve a type which has not yet been registered? 💣💥
- You end up with a huge "register" section in your app where you need to register all your types.

### SwiftiePod - Core concept

SwiftiePod takes a different approach. Instead of registering the builder in the container, you define a variable for the builder, called a `Provider`, and then you use this `Provider` to resolve instances from your container. There is no registration part!

This way, the container always knows how to build your instances. There will never be any app crashes due to not-registered types.

The two core components in SwiftiePod is the `SwiftiePod` and the `Providers`.

The `SwiftiePod` is your container. You use this to resolve your types.

The `Providers` are your builders. You pass these into the `pod` to get instances. For everything which you want to have an instance of, you define a `Provider`. It looks something like this:

```swift
let myCoolServiceProvider = Provider { _ in
    return MyCoolService()
}
```

And that's it! 🥳

### The Providers

As mentioned above, the `Providers` are your builders and the things you use to resolve a type. They are basically the building blocs which help you accomplish dependency injection.

For each type which you need instances from, you define a `Provider`. And then when you need an instance of that type you get it by passing that `Provider` to the `pod`.

```swift
let myCoolService = pod.resolve(myCoolServiceProvider)
```

If the type you are trying to build needs other types as input (dependency injection), then you can simply grab those types using the provided `pod` parameter passed into the builder method of your `Provider`.

```swift
let someServiceProvider = Provider { pod in // <-- Here you get a reference to your pod
    return SomeService(
        // Use that pod here to get any needed dependencies
        aDependency: pod.resolve(aDependencyProvider),
        anotherDependency: pod.resolve(anotherDependencyProvider)
    )
}
```

The typical flow of creating a `Provider` is usually at the top of the file where where you define your type:

```swift
let myCoolClassProvider = Provider { _ in
    return MyCoolClass()
}

class MyCoolClass {
    // Some interesting business logic
}
```

If you don't specify which type a `Provider` has, then it will implicitly get the same type as it's return value. You could also explicitly specify the type. For example if you have a protocol which you use as an abstraction layer.

```swift
// Will have this type `Provider<Int>`
let aNumberProvider = Provider { _ in
    return 123
}

// Will have this type `Provider<any CurrentUserServiceProtocol>`
let currentUserServiceProvider = Provider<CurrentUserServiceProtocol> { _ in
    return CurrentUserService()
}

protocol CurrentUserServiceProtocol {
    func username() -> String
}

class CurrentUserService: CurrentUserServiceProtocol {
    func username() -> String {
        return "Jane Doe"
    }
}
```

When you create your `Provider` you can also specify how its instances should be cached. You control this using the `Scope` parameter.

Out of the box, `SwiftiePod` provides you with 2 predefined scopes: `AlwaysCreateNewScope` and `SingletonScope`.

As you might be able to guess from the names, the `AlwaysCreateNewScope` will never cache instances. Every time you resolve a provider with this scope, it will run the builder and create a new instance.

And the `SingletonScope` will make sure to cache instances throughout the lifetime of your `pod`.

If you don't pass in a `scope` parameter to your `Provider`, then it will default to use `SingletonScope`.

You can also create your own custom scopes by implementing the `ProviderScope` protocol. This way, you could define a scope for a given flow of your app. For example you could have a specific scope for a sign-up flow in your app.

```swift
final class SignUpScope: ProviderScope {
    let children: [any ProviderScope] = []
}

let someSignUpProvider = Provider(scope: SignUpScope()) { _ in
    return SomeSignUp()
}
```

When the user completes the sign-up flow in your app, then you could easily clear all cached instances with that scope. So that the next time the user enters the sign-up flow, he gets new "clean" instances.

You can even layer custom scopes. Meaning that you could assign child scopes to your custom scopes. And then choose to clear only the child scopes or clear the parent scope (which would then make sure to also clear any child scopes)

```swift
final class SignUpScope: ProviderScope {
    let children: [any ProviderScope] = [SomeChildSignUpScope()]
}

final class SomeChildSignUpScope: ProviderScope {
    let children: [any ProviderScope] = []
}

let someChildSignUpProvider = Provider(scope: SomeChildSignUpScope()) { _ in
    return SomeChildSignUp()
}

// Clears all cached instances for SomeChildSignUpScope and SignUpScope
pod.clearCachedInstances(forScope: SignUpScope())

// Clears all cached instances for SomeChildSignUpScope
pod.clearCachedInstances(forScope: SomeChildSignUpScope())
```

One final thing to note about `Providers`:  
You could define multiple providers for the same type. Meaning you could for example have 2 `Providers` both returning a `String` type.  
And both of these would live independently and have their own cache and lifecycle.

```swift
let myAppTitleProvider = Provider { _ in
    return "My cool app"
}

let myAppDescriptionProvider = Provider { _ in
    return "This is a really exciting and cool app"
}

let string1 = pod.resolve(myAppTitleProvider) // <-- "My cool app"
let string2 = pod.resolve(myAppDescriptionProvider) // <-- "This is a really exciting and cool app"
```

### The SwiftiePod

The main task of the pod is to let you resolve providers to get some instances. 💃🪩🕺

Somewhere in your app you will need to define your pod by doing:

```swift
import SwiftiePod
...
let pod = SwiftiePod()
```

This is then the pod which you will use through your application.

Aside from resolving providers, the pod has 2 other functionalities. Overriding providers and clearing cached instances.

#### Overriding Providers

`Providers` are defined at compile time. But sometimes it might be useful to override/change the behavior of a `Provider` and change how it builds stuff. For example if you want to provide mock instances during testing or during ui previews.

The `pod` offers a `overrideProvider(...)` for this. You pass in which provider you want to override, and then a new build method which you want to use instead. Here is how it looks like:

```swift
pod.overrideProvider(myCoolServiceProvider) { _ in
    return MockMyCoolService()
}
```

Now, every time you call `pod.resolve(myCoolServiceProvider)` you will get back the `MockMyCoolService` instead of the real service.

When you want to remove an override for a given `Provider` you can call `pod.removeOverrideProvider(...)`. This will effectively remove the override and the provider will again return the original instance.

The instances you get from overridden providers can also be cached. By default, the override will use the same `Scope` as the provider you override. But you can change so that the override has its own `Scope`. To do this, just pass along a `scope` parameter when calling `overrideProvider(...)`.

#### Clearing cached instances

If your Provider has a `Scope` which is not `AlwaysCreateNewScope`, then the instances of your `Provider` will be cached in the `pod`. This means that the first time you call `pod.resolve(...)`, it will run the builder and create a new instance. But the second time you call `pod.resolve(...)`, then it will just return the cached instance.

Sometimes you might want to clear these caches, for example if some instances should only be active during a given flow of your app, like a sign-up flow. Then you could assign all those `Providers` a `SignUpFlowScope` and when you completed the sign-up flow, you could call `pod.clearCachedInstances(forScope: SignUpFlowScope())`.

This will make sure that all cached (with the SignUpFlowScope) are cleared from cache. So the next time a user enters the sign-up flow, all those instances would be recreated and "clean".

**NOTE:**  
Providers which are using the `SingletonScope` will ignore the `clearCachedInstances`, meaning that these instances will never be cleared. They are cached for the lifetime of your `pod`.

## Swift Concurrency

SwiftiePod is designed to work seamlessly with Swift's concurrency model, including projects that use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (the default in Xcode 26+).

### Important guidelines

**1. Define providers as top-level variables**

Always define your `Provider` instances at the top level of a file (module scope), not inside classes or structs:

```swift
// Correct: top-level provider
let myServiceProvider = Provider { _ in
    return MyService()
}

class MyService { ... }
```

```swift
// Avoid: provider inside a class
class SomeClass {
    let provider = Provider { _ in MyService() } // Don't do this
}
```

**2. Use the passed-in `pod` parameter for dependencies**

Inside a builder closure, always use the `pod` parameter that is passed in. Never capture and use the `SwiftiePod` instance directly, as this will cause a deadlock:

```swift
let pod = SwiftiePod()

// Correct: use the passed-in pod parameter
let serviceProvider = Provider { pod in
    return MyService(dependency: pod.resolve(otherProvider))
}

// Wrong: capturing the outer pod causes a deadlock
let badProvider = Provider { _ in
    return MyService(dependency: pod.resolve(otherProvider)) // Deadlock!
}
```

**3. Keep builder closures lightweight**

Builder closures run inside an internal serial queue. Keep them limited to simple object construction. Avoid heavy I/O, network calls, or dispatching synchronously to specific threads inside builders.

### How it works

SwiftiePod uses `@unchecked Sendable` on the `Provider` class to allow provider instances to be shared across concurrency boundaries. The builder closures are not marked `@Sendable`, which allows them to work with types that have any actor isolation (including implicitly `@MainActor` classes in Xcode 26+ projects).

The `SwiftiePod` container uses a serial dispatch queue to ensure all resolve operations are thread-safe. Singleton instances are created exactly once and cached for subsequent resolves.

### Thread safety

- All `resolve`, `overrideProvider`, `removeOverrideProvider`, and `clearCachedInstances` operations are thread-safe
- Concurrent calls to `resolve` from multiple threads are safe
- Singleton providers are guaranteed to create their instance only once

## Contributing

If you find a bug, want to request a new feature, or contribute in any other way, please [open an issue](https://github.com/robert-northmind/SwiftiePod/issues/new/choose) or submit a pull request.

## License

Distributed under the MIT license.
