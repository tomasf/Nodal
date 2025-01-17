// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DOM",
    products: [
        .library(name: "DOM", targets: ["DOM"]),
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
            path: "Sources/bridge"
        ),
        .target(
            name: "DOM",
            dependencies: ["pugixml", "Bridge"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(name: "Test", dependencies: ["DOM"], swiftSettings: [.interoperabilityMode(.Cxx)])
    ],
    cxxLanguageStandard: .cxx17
)
