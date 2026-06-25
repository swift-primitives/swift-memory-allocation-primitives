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

        // MARK: - Allocator capability protocol (the seam triple home)
        .library(
            name: "Memory Allocator Protocol Primitives",
            targets: ["Memory Allocator Protocol Primitives"]
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

        // MARK: - Allocation Primitive (namespace + the seam triple)
        .library(
            name: "Memory Allocation Primitive",
            targets: ["Memory Allocation Primitive"]
        ),

        // MARK: - Umbrella
        // This package now owns the canonical "Memory Allocation Primitives" module:
        // swift-memory-primitives no longer declares an allocation product/target, so the
        // backing umbrella target reclaims the bare "Memory Allocation Primitives" name.
        .library(
            name: "Memory Allocation Primitives",
            targets: ["Memory Allocation Primitives"]
        ),

        // MARK: - Test Support (the pool law harness L1–L5)
        .library(
            name: "Memory Allocation Primitives Test Support",
            targets: ["Memory Allocation Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-memory-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-bit-vector-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-affine-primitives.git", branch: "main"),
    ],
    targets: [
        // MARK: - Namespace
        .target(
            name: "Memory Allocator Primitive",
            dependencies: [
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
                .product(name: "Memory Region Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
            ]
        ),

        // MARK: - Allocator capability protocol (the seam triple home + the Allocatable/Growable seams)
        .target(
            name: "Memory Allocator Protocol Primitives",
            dependencies: [
                "Memory Allocator Primitive",
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
                .product(name: "Memory Region Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
            ]
        ),

        // MARK: - Allocation Primitive (namespace + the seam triple)
        .target(
            name: "Memory Allocation Primitive",
            dependencies: [
                "Memory Allocator Primitive",
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),

        // MARK: - Arena strategy
        .target(
            name: "Memory Allocator Arena Primitives",
            dependencies: [
                "Memory Allocator Primitive",
                "Memory Allocator Protocol Primitives",
                "Memory Allocation Primitive",
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
                .product(name: "Memory Region Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Standard Library Integration", package: "swift-memory-primitives"),
            ]
        ),

        // MARK: - Pool strategy
        .target(
            name: "Memory Allocator Pool Primitives",
            dependencies: [
                "Memory Allocator Primitive",
                "Memory Allocator Protocol Primitives",
                "Memory Allocation Primitive",
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
                .product(name: "Memory Region Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Standard Library Integration", package: "swift-memory-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Affine Discrete Primitives", package: "swift-affine-primitives"),
                .product(name: "Affine Primitives Standard Library Integration", package: "swift-affine-primitives"),
            ]
        ),

        // MARK: - Umbrella
        .target(
            name: "Memory Allocation Primitives",
            dependencies: [
                "Memory Allocator Primitive",
                "Memory Allocator Protocol Primitives",
                "Memory Allocation Primitive",
                "Memory Allocator Arena Primitives",
                "Memory Allocator Pool Primitives",
            ]
        ),

        // MARK: - Test Support (the pool law harness L1–L5)
        .target(
            name: "Memory Allocation Primitives Test Support",
            dependencies: [
                "Memory Allocator Pool Primitives",
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
        //
        // In-package tests exercise ONLY the generic / element-free surface (the new
        // `Memory.Allocatable` adopt-role + `Memory.Growable` fresh-construction seams over a
        // test-local region stub). The concrete `Memory.Heap` / `Memory.Inline` allocator integration
        // suites + the heap pool-law application live in the leaf packages (post dependency-inversion:
        // the leaves depend on allocation, never the reverse), where they can name the concrete leaves
        // without re-introducing a package cycle.
        .testTarget(
            name: "Memory Allocation Primitives Tests",
            dependencies: [
                "Memory Allocation Primitives",
                "Memory Allocation Primitives Test Support",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
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
