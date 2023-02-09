// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrepViews",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PrepViews",
            targets: ["PrepViews"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pxlshpr/PrepDataTypes", from: "0.0.250"),
        .package(url: "https://github.com/pxlshpr/PrepMocks", from: "0.0.3"),
        .package(url: "https://github.com/pxlshpr/FoodLabel", from: "0.0.48"),
        .package(url: "https://github.com/pxlshpr/SwiftUISugar", from: "0.0.361"),
        
        .package(url: "https://github.com/fermoya/SwiftUIPager", from: "2.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PrepViews",
            dependencies: [
                .product(name: "PrepDataTypes", package: "prepdatatypes"),
                .product(name: "PrepMocks", package: "prepmocks"),
                .product(name: "FoodLabel", package: "foodlabel"),
                .product(name: "SwiftUISugar", package: "swiftuisugar"),
                
                .product(name: "SwiftUIPager", package: "swiftuipager"),
            ]),
        .testTarget(
            name: "PrepViewsTests",
            dependencies: ["PrepViews"]),
    ]
)
