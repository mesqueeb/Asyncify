// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Asyncify",
  platforms: [.macOS(.v10_15), .iOS(.v13), .watchOS(.v6), .tvOS(.v13)],
  products: [
    .library(
      name: "Asyncify",
      targets: ["Asyncify"]
    ),
  ],
  targets: [
    .target(
      name: "Asyncify"
    ),
    .testTarget(
      name: "AsyncifyTests",
      dependencies: ["Asyncify"]
    ),
  ]
)
