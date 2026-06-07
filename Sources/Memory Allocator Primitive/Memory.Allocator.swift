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
    /// The allocator namespace — the agent of the operation-domain triple applied to allocation.
    ///
    /// `Memory.Allocator` is a pure, non-generic `enum` namespace (per
    /// `operation-domain-naming-and-organization.md` §3). It hosts the agent protocol
    /// `Memory.Allocator.\`Protocol\`` (the allocate/deallocate seam), the type-erased witness
    /// `Memory.Allocator.Witness`, the standalone strategies `Memory.Allocator.Arena` (bump) and
    /// `Memory.Allocator.Pool` (free-list), and the static factories `Memory.Allocator.system`,
    /// `Memory.Allocator.arena(…)`, and `Memory.Allocator.pool(…)`.
    ///
    /// ## Namespace, not a concrete allocator
    ///
    /// In the prior `swift-memory-primitives` shape, `Memory.Allocator` was a `struct` that
    /// doubled as both the namespace *and* the concrete system allocator. Here the two roles are
    /// split: `Memory.Allocator` is **only** the namespace, and the system allocator is the static
    /// witness `Memory.Allocator.system` (a `Memory.Allocator.Witness<Never>`). This mirrors the
    /// `Iterator` namespace, which is likewise a pure `enum` hosting `Iterator.\`Protocol\``,
    /// `Iterator.Witness`, and `Iterator.repeating(_:)`.
    ///
    /// The active capability protocol `Memory.Allocator.\`Protocol\`` carries the gerund alias
    /// `Memory.Allocating` (the capability you *conform to*), scoped under `Memory`.
    public enum Allocator {}
}
