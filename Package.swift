// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "Skull",
  products: [
    .library(name: "Skull", targets: ["Skull"])
  ],
  targets: [
    .systemLibrary(name: "CSqlite3", path: "module/macosx"),
    .target(name: "Skull", dependencies: ["CSqlite3"], path: "Sources"),
    .testTarget(name: "SkullTests", dependencies: ["Skull"])
  ],
  swiftLanguageVersions: [.v4_2]
)
