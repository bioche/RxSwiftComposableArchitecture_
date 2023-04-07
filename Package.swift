// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "Rx-swift-composable-architecture",
  platforms: [
    // these are arbitrary but seem reasonable. Below this we will have to add even more @available annotations.
    .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
  ],
  products: [
    .library(
      name: "RxComposableArchitecture",
      targets: ["RxComposableArchitecture"]
    )
  ],
  dependencies: [
  .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0")
  ],
  targets: [
    .target(
      name: "RxComposableArchitecture",
      dependencies: ["RxSwift", "RxCocoa"]
    ),
    .testTarget(
      name: "RxComposableArchitectureTests",
      dependencies: [
        "RxComposableArchitecture", "RxTest"
      ]
    )
  ]
)
