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
      targets: ["ComposableArchitecture"]
    ),
    .library(
      name: "ComposableDifferenceKitDatasources",
      targets: ["ComposableDifferenceKitDatasources"]
    )
  ],
  dependencies: [
  .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
  .package(url: "https://github.com/ra1028/DifferenceKit.git", from: "1.1.5")
  ],
  targets: [
    .target(
      name: "ComposableArchitecture",
      dependencies: ["RxSwift", "RxCocoa"]
    ),
    .testTarget(
      name: "ComposableArchitectureTests",
      dependencies: [
        "ComposableArchitecture", "RxTest"
      ]
    ),
    .target(name: "ComposableDifferenceKitDatasources",
    dependencies: [
      "ComposableArchitecture",
      "DifferenceKit"
    ])
  ]
)
