//
//  CyclicDependencyHandler.swift
//  SwiftiePod
//
//  Created by Robert Magnusson on 16.02.26.
//

import Foundation

/// Internal handler for cyclic dependency errors.
/// Replaceable to allow testing code paths that trigger cycle detection.
var cyclicDependencyHandler: (String) -> Never = { message in
    Swift.fatalError(message)
}
