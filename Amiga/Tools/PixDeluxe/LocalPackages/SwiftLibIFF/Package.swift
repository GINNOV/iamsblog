// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftLibIFF",
    products: [
        .library(
            name: "SwiftLibIFF",
            targets: ["SwiftLibIFF"]
        ),
    ],
    targets: [
        // C library target
        .target(
            name: "Clibiff",
            path: "Sources/Clibiff/src",
            exclude: [
                "Doxyfile",
                "libiff.sln",
                "libiff.pc.in",
                "iffjoin",
                "iffpp",
                "libiff/Makefile.am",
                "libiff/libiff.vcxproj",
                "libiff/libiff.vcxproj.filters",
                "libiff/libiff.def"
            ],
            sources: ["libiff"],
            publicHeadersPath: "libiff/include",
            cSettings: [
                .headerSearchPath("../include"),
                .headerSearchPath("libiff"),
                .headerSearchPath("libiff/include"),
                .define("HAVE_CONFIG_H"),
                .define("PACKAGE_DATA_DIR=\"\\\"/usr/local/share/libiff\\\"\""),
                .unsafeFlags(["-Wno-unused-command-line-argument"])
            ],
            linkerSettings: [
                .linkedLibrary("m")
            ]
        ),
        
        // Swift wrapper target
        .target(
            name: "SwiftLibIFF",
            dependencies: ["Clibiff"],
            path: "Sources/SwiftLibIFF"
        ),
        
        // Test target
        .testTarget(
            name: "SwiftLibIFFTests",
            dependencies: ["SwiftLibIFF"]
        )
    ]
)