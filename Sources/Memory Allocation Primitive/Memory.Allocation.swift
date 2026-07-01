// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-memory-allocation-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-memory-allocation-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Memory {
    /// Namespace for allocation tracking, profiling, and system allocation parameters.
    ///
    /// ## Platform Implementation
    ///
    /// System allocation granularity is provided by platform-specific packages:
    /// - POSIX: `swift-iso-9945` (`extension Memory.Allocation { static var system }`)
    /// - Windows: `swift-windows-standard` (`extension Memory.Allocation { static var system }`)
    public enum Allocation {}
}

extension Memory.Allocation {
    /// System allocation granularity.
    ///
    /// Represents the granularity at which the system allocates memory.
    /// On POSIX systems, this equals the page size.
    /// On Windows, this is typically 64KB (larger than page size).
    ///
    /// Tagged wrapper around `Memory.Alignment` providing type-safe distinction
    /// between system allocation granularity and arbitrary alignments.
    public typealias Granularity = Tagged<Memory.Allocation, Memory.Alignment>
}
