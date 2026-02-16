//
//  ContentViewModel.swift
//  ExampleIosApp
//
//  Created by Robert Magnusson on 16.02.26.
//

import Foundation
import SwiftiePod

// MARK: - ViewModel

class MyViewModel {
    let service: MyService
    let backgroundService: BackgroundService

    init(service: MyService, backgroundService: BackgroundService) {
        self.service = service
        self.backgroundService = backgroundService
    }

    var description: String {
        "ViewModel using \(service.name) and \(backgroundService.name)"
    }
}

// MARK: - ViewModel Provider

// Provider with a dependency chain — use the passed-in `pod` parameter
// Using .factory scope so each view gets its own instance
let viewModelProvider = Provider(scope: AlwaysCreateNewScope()) { pod in
    return MyViewModel(
        service: pod.resolve(myServiceProvider),
        backgroundService: pod.resolve(backgroundServiceProvider)
    )
}
