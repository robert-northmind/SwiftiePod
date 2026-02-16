# Swift Concurrency Fix: Provider Builder Closure

## Problem

When using SwiftiePod in an Xcode 26+ project with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (the new default for iOS apps), users encountered a compiler error when defining providers for their classes:

```swift
let myServiceProvider = Provider { pod in
    return MyService()
}
```

**Error:**
```
Call to main actor-isolated initializer 'init()' in a synchronous nonisolated context
```

**Root cause:** With `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, all classes are implicitly `@MainActor`. The `Provider` class previously required `@Sendable` on its builder closure, which forces the closure to be nonisolated. A nonisolated closure cannot call `@MainActor`-isolated initializers.

## Solution

Removed the `@Sendable` constraint from the builder closure and changed `Provider` to `@unchecked Sendable`:

### Before:
```swift
public final class Provider<T>: Hashable, Sendable {
    public init(
        scope: ProviderScope = SingletonScope(),
        _ builder: @escaping @Sendable (ProviderResolver) -> T
    ) { ... }

    private let builder: @Sendable (ProviderResolver) -> T
}
```

### After:
```swift
public final class Provider<T>: Hashable, @unchecked Sendable {
    public init(
        scope: ProviderScope = SingletonScope(),
        _ builder: @escaping (ProviderResolver) -> T
    ) { ... }

    private let builder: (ProviderResolver) -> T
}
```

The same change was applied to `overrideProvider` in `SwiftiePod.swift` and `ProviderOverrider.swift` for consistency.

## Why `@unchecked Sendable`

`Provider` needs to be `Sendable` so it can be stored as a top-level `let` and shared across concurrency boundaries. However, with a non-`@Sendable` builder closure stored as a property, the compiler cannot automatically verify `Sendable` conformance. We use `@unchecked Sendable` because:

- `Provider` is immutable after initialization (all stored properties are `let`)
- The builder closure is stored but never mutated
- All access to the builder goes through the `SwiftiePod` container's serial queue, which provides thread safety

This is a pragmatic trade-off: we opt out of the compiler's `@Sendable` closure checking to provide an ergonomic API for the common case of DI object construction.

## Requirements for safe usage

1. **Define providers as top-level variables** — not inside classes or actor-isolated contexts
2. **Use the passed-in `pod` parameter** inside builder closures — never capture and call the `SwiftiePod` instance directly (causes deadlock)
3. **Keep builders lightweight** — simple object construction only, no heavy I/O or synchronous dispatch to specific threads

## Additional fixes

- **`clearAllInstances` synchronization:** Added missing `dispatchQueue.sync` wrapper in `ProviderInstanceContainer.clearAllInstances(forScope:)` to match all other methods in the class
- **`overrideProvider` consistency:** Removed `@Sendable` from the override builder closure to match the `Provider` init signature

## Files modified

1. `Sources/SwiftiePod/Provider.swift` — Removed `@Sendable`, changed to `@unchecked Sendable`
2. `Sources/SwiftiePod/SwiftiePod.swift` — Removed `@Sendable` from `overrideProvider` builder
3. `Sources/SwiftiePod/ProviderOverrider.swift` — Removed `@Sendable` from `overrideProvider` builder
4. `Sources/SwiftiePod/ProviderInstanceContainer.swift` — Added `dispatchQueue.sync` to `clearAllInstances`

## Testing

- **33 Swift package tests** pass (`swift test`)
- **12 iOS example app tests** pass with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` enabled
- Zero compiler warnings in both the package and the example app
