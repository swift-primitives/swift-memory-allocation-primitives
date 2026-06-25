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

public import Memory_Primitive

extension Memory {
    /// The [PKG-NAME-002] gerund capability alias for `Memory.Pool.\`Protocol\``
    /// (the `Iterating` precedent; Memory-nested to match `Memory.Allocating`'s
    /// domain placement).
    ///
    /// Bound-position sugar so constraint sites read as English:
    ///
    /// ```swift
    /// extension Storage.Generational where Allocation: Memory.Pooling { … }
    /// ```
    ///
    /// Canonical references use the noun path (`Memory.Pool.\`Protocol\``); the gerund
    /// names the active capability you *conform to*.
    public typealias Pooling = Memory.Pool.`Protocol`
}
