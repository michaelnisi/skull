// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Skull",
  platforms: [.iOS("13.0")],
  products: [
    .library(
      name: "Skull",
      targets: ["Skull"]),
  ],
  dependencies: [
    .package(url: "https://github.com/michaelnisi/csqlite.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "Skull",
      dependencies: []),
    .testTarget(
      name: "SkullTests",
      dependencies: ["Skull"]),
  ]
)
