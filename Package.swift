// swift-tools-version:5.3
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
      dependencies: ["CSqlite3"]),
    .testTarget(
      name: "SkullTests",
      dependencies: ["Skull"]),
    .systemLibrary(
      name: "CSqlite3", path: "./CSqlite3"
    )
  ]
)

