// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Skull",
  products: [
    .library(
      name: "Skull",
      targets: ["Skull"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "Skull",
      dependencies: []),
    .testTarget(
      name: "SkullTests",
      dependencies: ["Skull"])
  ]
)

