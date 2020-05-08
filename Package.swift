// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "swift-composable-architecture",
  platforms: [
    // these are arbitrary but seem reasonable. Below this we will have to add even more @available annotations.
    .macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)
  ],
  products: [
    .library(
      name: "ComposableArchitecture",
      type: .dynamic,
      targets: ["ComposableArchitecture"]
    ),
    .library(
      name: "ComposableArchitectureTestSupport",
      type: .dynamic,
      targets: ["ComposableArchitectureTestSupport"]
    ),
  ],
  dependencies: [.package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0"),
                 .package(url: "https://github.com/bioche/RxCombine.git", .branch("ios_compatibility"))],
  targets: [
    .target(
      name: "ComposableArchitecture",
      dependencies: ["RxSwift", "RxCombine"]
    ),
    .testTarget(
      name: "ComposableArchitectureTests",
      dependencies: [
        "ComposableArchitecture",
        "ComposableArchitectureTestSupport",
      ]
    ),
    .target(
      name: "ComposableArchitectureTestSupport",
      dependencies: [
        "ComposableArchitecture",
      ]
    ),
  ]
)
