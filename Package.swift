// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "Skull",
  platforms: [
    .iOS(.v10)
  ],
  products: [
    .library(name: "Skull", targets: ["Skull"])
  ],
  targets: [
    .systemLibrary(name: "CSqlite3", path: "Libraries/CSqlite3"),
    .target(name: "Skull", dependencies: ["CSqlite3"], path: "Sources"),
    .testTarget(name: "SkullTests", dependencies: ["Skull"])
  ]
)
