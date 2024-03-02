// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "HaishinKit",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .visionOS(.v1),
        .macOS(.v10_13),
        .macCatalyst(.v14)
    ],
    products: [
        .library(name: "HaishinKit", targets: ["HaishinKit"]),
        .library(name: "SRTHaishinKit", targets: ["SRTHaishinKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/shogo4405/Logboard.git", "2.4.1"..<"2.5.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0")
    ],
    targets: [
        .binaryTarget(
            name: "libsrt",
            path: "Vendor/SRT/libsrt.xcframework"
        ),
        .target(name: "SwiftPMSupport"),
        .target(name: "HaishinKit",
                dependencies: ["Logboard", "SwiftPMSupport"],
                path: "Sources",
                sources: [
                    "Codec",
                    "Extension",
                    "FLV",
                    "IO",
                    "MPEG",
                    "Net",
                    "RTMP",
                    "Util"
                ]),
        .target(name: "SRTHaishinKit",
                dependencies: [
                    "libsrt",
                    "HaishinKit"
                ],
                path: "SRTHaishinKit"
        )
    ]
)
