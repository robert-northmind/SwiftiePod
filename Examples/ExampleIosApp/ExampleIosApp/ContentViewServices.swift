//
//  ContentViewServices.swift
//  ExampleIosApp
//
//  Created by Robert Magnusson on 16.02.26.
//

import Foundation
import SwiftiePod

// MARK: - Service classes

class MyService {
    let name = "MyService"
}

nonisolated class BackgroundService {
    let name = "BackgroundService"
    nonisolated init() {}
}

// MARK: - Service Providers

// Provider for a class (implicitly @MainActor due to SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor)
let myServiceProvider = Provider { _ in
    return MyService()
}

// Provider for an explicitly nonisolated class
let backgroundServiceProvider = Provider { _ in
    return BackgroundService()
}
