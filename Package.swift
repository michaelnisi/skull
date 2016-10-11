import PackageDescription

let package = Package(
  name: "Skull",
  dependencies: [
    .Package(url: "git@github.com:michaelnisi/csqlite.git", majorVersion: 1)
  ]
)
