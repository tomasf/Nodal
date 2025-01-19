// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Nodal",
    products: [
        .library(name: "Nodal", targets: ["Nodal"]),
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
            name: "Nodal",
            dependencies: ["pugixml", "Bridge"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(name: "Tests", dependencies: ["Nodal"], swiftSettings: [.interoperabilityMode(.Cxx)])
    ],
    cxxLanguageStandard: .cxx17
)
