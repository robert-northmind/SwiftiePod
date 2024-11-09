//
//  ProviderResolver.swift
//  SwiftPod
//
//  Created by Robert Magnusson on 09.11.24.
//

public protocol ProviderResolver {
    func resolve<T>(_ provider: Provider<T>) -> T
}
