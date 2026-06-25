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
    /// The **adopt-role** of the allocation domain — the source half of the codec-style pairing
    /// whose agent half is `Memory.Allocator`.
    ///
    /// `Memory.Allocatable` is the `Iterable`-analogue: an *element-free* `Memory.Region` that can
    /// hand itself over to become an allocator (`makeAllocator()`), exactly as `Iterable` vends an
    /// `Iterator` via `makeIterator()`. The agent (`Memory.Allocator` / `Memory.Allocator.\`Protocol\``
    /// / `Memory.Allocating`) *carves and recycles* bytes; the adopt-role merely *opts a region in* as
    /// something an allocator can be built over. They are orthogonal: a region is `Memory.Allocatable`
    /// (can be adopted) without itself being an allocator.
    ///
    /// Conformed by every raw region — `Memory.Heap`, `Memory.Inline`, and `Memory.Small` — because
    /// each exposes the `Memory.Region` seam (`base` + `capacity`) that a passthrough
    /// `Memory.Allocator<Self>` adopts. **Distinct from `Memory.Growable`**: adoption is universal
    /// (every region can be adopted as-is); fresh byte-count *construction* (`Memory.Growable`) is a
    /// separate capability that only the growable regions (`Memory.Heap`, `Memory.Small`) carry.
    ///
    /// Mirrors `Iterable`'s plain-protocol shape: the protocol is hoisted to module scope as
    /// `__MemoryAllocatableProtocol` (the [API-IMPL-009] self-reference avoidance) and re-exposed here
    /// as the `Memory`-namespaced name. Declaring-module / sibling conformers (`Memory.Heap`,
    /// `Memory.Inline`, `Memory.Small`) conform via the hoisted name; consumers spell it
    /// `Memory.Allocatable`.
    public typealias Allocatable = __MemoryAllocatableProtocol
}
