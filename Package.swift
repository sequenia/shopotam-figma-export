// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "shopotam-figma-export",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .executable(name: "shopotam-figma-export", targets: ["FigmaExport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.14.0"),
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.7.1"),
    ],
    targets: [
        // Main target
        .target(
            name: "FigmaExport",
            dependencies: [
                "FigmaAPI",
                "FigmaExportCore",
                "XcodeExport",
                "AndroidExport",
                "Utils",
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "./Sources/FigmaExport"
        ),
        
        // Shared target
        .target(
            name: "FigmaExportCore",
            path: "./Sources/FigmaExportCore"
        ),
        
        // Loads data via Figma REST API
        .target(
            name: "FigmaAPI",
            dependencies: ["FigmaExportCore"],
            path: "./Sources/FigmaAPI"
        ),
        
        // Exports resources to Xcode project
        .target(
            name: "Utils",
            dependencies: ["FigmaExportCore", "Stencil"],
            path: "./Sources/Utils"
        ),
        .target(
            name: "XcodeExport",
            dependencies: ["FigmaExportCore", "Stencil", "FigmaAPI"],
            path: "./Sources/XcodeExport"
        ),
        // Exports resources to Android project
        .target(
            name: "AndroidExport",
            dependencies: ["FigmaExportCore", "FigmaAPI"],
            path: "./Sources/AndroidExport"
        )
    ]
)
