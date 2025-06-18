// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CLibIFF",
    products: [
        .library(
            name: "CLibIFF",
            targets: ["CLibIFF"]),
    ],
    targets: [
        // This defines the C library target.
        // By convention, SPM looks for sources in "Sources/CLibIFF/"
        // and public headers in "Sources/CLibIFF/include/".
        .target(
            name: "CLibIFF",
            dependencies: []
        ),
        
        // You can keep or remove the test target depending on your needs.
        .testTarget(
            name: "CLibIFFTests",
            dependencies: ["CLibIFF"]
        ),
    ]
)