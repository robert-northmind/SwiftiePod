// swift-tools-version: 5.8
// This Package.swift exists so that SPM treats this directory as a separate
// package and excludes it from the parent SwiftiePod package's file listing.
// The actual build is done via the .xcodeproj.

import PackageDescription

let package = Package(
    name: "ExampleIosApp"
)
