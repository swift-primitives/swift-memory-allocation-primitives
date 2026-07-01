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
    /// The [PKG-NAME-002] gerund capability alias for `Memory.Allocator.`Protocol``
    /// (the `Iterating`/`Memory.Pooling` precedent; `Memory`-scoped, never a bare top-level
    /// `Allocating` and never `Memory.Allocator.Allocating`).
    ///
    /// Bound-position sugar so constraint and conformance sites read as English:
    ///
    /// ```swift
    /// extension Memory.Allocator.Pool: Memory.Allocating where Resource: ~Copyable {}
    /// ```
    ///
    /// The RHS targets the hoisted `__MemoryAllocatorProtocol` directly (the same protocol
    /// `Memory.Allocator.`Protocol`` denotes) so the gerund stays resolvable from module scope —
    /// `Memory.Allocator.`Protocol`` cannot be named unbound in a typealias RHS ([PKG-NAME-006]).
    /// Canonical references use the noun path (`Memory.Allocator.`Protocol``); the gerund names the
    /// active capability you *conform to*. Declaring-module / sibling conformers conform via the
    /// hoisted name to avoid the [API-IMPL-009] self-reference cycle.
    public typealias Allocating = __MemoryAllocatorProtocol
}
