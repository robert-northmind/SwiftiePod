# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2026-02-16

### Fixed

- Examples folder no longer appears in Xcode's dependency navigator for SPM consumers. The `Package.swift` in `Examples/ExampleIosApp/` now defines a proper target so SPM recognizes it as a separate nested package.

## [1.1.1] - 2026-02-16

### Fixed

- (Superseded by 1.1.2) Initial attempt to hide Examples from SPM navigator.

## [1.1.0] - 2026-02-16

### Added

- Swift Concurrency section in README with usage guidelines.
- iOS example app (`Examples/ExampleIosApp`) demonstrating SwiftiePod with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- iOS build and test steps in CI workflow.
- Cyclic dependency detection is now testable and covered by tests.

### Changed

- `Provider` is now `@unchecked Sendable` with a non-`@Sendable` builder closure. This allows providers to work seamlessly in Xcode 26+ projects where `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` makes all classes implicitly `@MainActor`. Previously, the `@Sendable` requirement on the builder closure caused compiler errors when constructing these classes.
- `overrideProvider` builder parameter no longer requires `@Sendable`, matching the `Provider` init signature.
- Pinned GitHub Actions to commit hashes and added least-privilege permissions.

### Fixed

- `ProviderInstanceContainer.clearAllInstances(forScope:)` now runs inside `dispatchQueue.sync`, fixing a missing synchronization bug where the scope dictionary could be mutated without its lock.

## [1.0.8] - 2024-12-22

### Added

- CocoaPods support.
- Dependency cycle detection with descriptive error messages.
- Custom scope hierarchies with parent/child relationships.
- Scope-based cache clearing (`clearCachedInstances(forScope:)`).
- Provider override support for testing and dynamic behavior.
- Thread-safe concurrent resolution via internal serial dispatch queue.

## [1.0.0] - 2024-10-17

### Added

- Initial release.
- `SwiftiePod` container for resolving dependencies.
- `Provider<T>` with compile-time safe dependency resolution.
- `SingletonScope` and `AlwaysCreateNewScope` built-in scopes.
- Swift Package Manager support.

[1.1.2]: https://github.com/robert-northmind/SwiftiePod/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/robert-northmind/SwiftiePod/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/robert-northmind/SwiftiePod/compare/1.0.8...1.1.0
[1.0.8]: https://github.com/robert-northmind/SwiftiePod/compare/1.0.0...1.0.8
[1.0.0]: https://github.com/robert-northmind/SwiftiePod/releases/tag/1.0.0
