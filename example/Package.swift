// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "example",
  dependencies: [
    .package(url: "https://github.com/michaelnisi/skull",
    .upToNextMajor(from: "8.0.0"))
  ],
  targets: [
    .target( name: "example", dependencies: ["Skull"])]
)
