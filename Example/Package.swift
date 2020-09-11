// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Example",
  dependencies: [
    .package(url: "../", from: "11.0.0")
  ],
  targets: [
    .target(
      name: "Example",
      dependencies: []),
    .testTarget(
      name: "ExampleTests",
      dependencies: ["Example"]),
  ]
)
