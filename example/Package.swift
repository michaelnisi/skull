// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "example",
  dependencies: [
    .package(url: "https://github.com/michaelnisi/skull", from: "5.0.0")
  ],
  targets: [
    .target( name: "example", dependencies: ["Skull"])]
)
