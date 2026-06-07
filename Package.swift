// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-memory-allocation-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        // MARK: - Namespace
        .library(
            name: "Memory Allocator Primitive",
            targets: ["Memory Allocator Primitive"]
        ),

        // MARK: - Protocol
        .library(
            name: "Memory Allocator Protocol",
            targets: ["Memory Allocator Protocol"]
        ),

        // MARK: - Witness
        .library(
            name: "Memory Allocator Witness Primitives",
            targets: ["Memory Allocator Witness Primitives"]
        ),

        // MARK: - Arena strategy
        .library(
            name: "Memory Allocator Arena Primitives",
            targets: ["Memory Allocator Arena Primitives"]
        ),

        // MARK: - Pool strategy
        .library(
            name: "Memory Allocator Pool Primitives",
            targets: ["Memory Allocator Pool Primitives"]
        ),

        // MARK: - Allocation Result
        .library(
            name: "Memory Allocation Result",
            targets: ["Memory Allocation Result"]
        ),

        // MARK: - Umbrella
        // This package now owns the canonical "Memory Allocation Primitives" module:
        // swift-memory-primitives no longer declares an allocation product/target, so the
        // backing umbrella target reclaims the bare "Memory Allocation Primitives" name.
        .library(
            name: "Memory Allocation Primitives",
            targets: ["Memory Allocation Primitives"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-memory-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-bit-vector-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
    ],
    targets: [
        // MARK: - Namespace
        .target(
            name: "Memory Allocator Primitive",
            dependencies: [
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
            ]
        ),

        // MARK: - Protocol
        .target(
            name: "Memory Allocator Protocol",
            dependencies: [
                "Memory Allocator Primitive",
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
            ]
        ),

        // MARK: - Witness
        .target(
            name: "Memory Allocator Witness Primitives",
            dependencies: [
                "Memory Allocator Protocol",
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Standard Library Integration", package: "swift-memory-primitives"),
            ]
        ),

        // MARK: - Allocation Result
        .target(
            name: "Memory Allocation Result",
            dependencies: [
                "Memory Allocator Primitive",
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),

        // MARK: - Arena strategy
        .target(
            name: "Memory Allocator Arena Primitives",
            dependencies: [
                "Memory Allocator Protocol",
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Standard Library Integration", package: "swift-memory-primitives"),
                .product(name: "Memory Contiguous Primitives", package: "swift-memory-primitives"),
                .product(name: "Byte Primitive", package: "swift-byte-primitives"),
            ]
        ),

        // MARK: - Pool strategy
        .target(
            name: "Memory Allocator Pool Primitives",
            dependencies: [
                "Memory Allocator Protocol",
                "Memory Allocation Result",
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Standard Library Integration", package: "swift-memory-primitives"),
                .product(name: "Memory Contiguous Primitives", package: "swift-memory-primitives"),
                .product(name: "Byte Primitive", package: "swift-byte-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
            ]
        ),

        // MARK: - Umbrella
        .target(
            name: "Memory Allocation Primitives",
            dependencies: [
                "Memory Allocator Primitive",
                "Memory Allocator Protocol",
                "Memory Allocator Witness Primitives",
                "Memory Allocator Arena Primitives",
                "Memory Allocator Pool Primitives",
                "Memory Allocation Result",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
