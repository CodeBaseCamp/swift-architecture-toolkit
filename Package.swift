// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "swift-architecture-toolkit",
  platforms: [
    .macOS(.v12),
    .iOS(.v15),
  ],
  products: [
    .library(name: "ART", targets: ["ART"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Quick/Nimble.git", branch: "main"),
    .package(url: "https://github.com/Quick/Quick.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "ART",
      dependencies: [

      ]
    ),
    .testTarget(
      name: "ARTTests",
      dependencies: ["ART", "Quick", "Nimble"]
    ),
  ]
)
