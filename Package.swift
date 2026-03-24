// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "SagaWebsite",
  platforms: [
    .macOS(.v14),
  ],
  dependencies: [
    // .package(url: "https://github.com/loopwerk/Saga", from: "2.20.0"),
    .package(path: "../Saga/"),
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaSwimRenderer", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SwiftTailwind", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaUtils", from: "1.0.2"),
    .package(url: "https://github.com/loopwerk/Moon", from: "1.2.3"),
    .package(url: "https://github.com/loopwerk/Bonsai", from: "1.1.0"),
    .package(url: "https://github.com/loopwerk/Sigil", branch: "main"),
  ],
  targets: [
    .executableTarget(
      name: "Website",
      dependencies: [
        "Saga",
        "SagaParsleyMarkdownReader",
        "SagaSwimRenderer",
        "SwiftTailwind",
        "SagaUtils",
        "Moon",
        "Bonsai",
        "Sigil",
      ],
      path: "Sources/Website"
    ),
  ]
)
