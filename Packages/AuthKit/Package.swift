// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuthKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AuthKit",
            targets: ["AuthKit"]
        ),
    ],
    dependencies: [
        .package(path: "../SecurityKit"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AuthKit",
            dependencies: [
                .product(name: "SecurityKit", package: "SecurityKit"),
            ]
        ),
        .testTarget(
            name: "AuthKitTests",
            dependencies: [
                "AuthKit",
                .product(name: "SecurityKit", package: "SecurityKit"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
