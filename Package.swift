// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Nodal",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(name: "Nodal", targets: ["Nodal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest")
    ],
    targets: [
        .target(
            name: "pugixml",
            sources: ["src/pugixml.cpp"],
            publicHeadersPath: "src",
            cxxSettings: [.define("PUGIXML_NO_EXCEPTIONS")]
        ),
        .target(
            name: "Bridge",
            dependencies: ["pugixml"],
            path: "Sources/bridge",
            publicHeadersPath: "."
        ),
        .target(
            name: "Nodal",
            dependencies: ["pugixml", "Bridge", "NodalMacros"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .macro(
            name: "NodalMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "Tests",
            dependencies: ["Nodal"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ],
    cxxLanguageStandard: .cxx17
)
