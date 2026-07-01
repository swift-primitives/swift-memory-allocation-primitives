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

public import Memory_Allocator_Primitive
public import Memory_Primitive
public import Memory_Region_Primitives

/// The **adopt-role** seam: an element-free `Memory.Region` that can become an allocator.
///
/// This is the source half of the allocation domain's source/agent pairing — the `Iterable`
/// analogue. A conformer is a raw region (`base` + `capacity`, via the `Memory.Region` refinement)
/// that vends a passthrough `Memory.Allocator<Self>` over itself. The agent half
/// (`Memory.Allocator.\`Protocol\``) is the active capability you *carve through*; this adopt-role is
/// what a region *is* so that an allocator can be built over it.
///
/// Hoisted to module scope as `__MemoryAllocatableProtocol` and re-exposed as the plain
/// `Memory`-namespaced typealias `Memory.Allocatable` (the `Iterable` shape), so consumers spell it
/// `Memory.Allocatable`. Declaring-module / sibling conformers (`Memory.Heap`, `Memory.Inline`,
/// `Memory.Small`) conform via the hoisted name, never via the namespaced alias (the [API-IMPL-009]
/// self-reference cycle).
public protocol __MemoryAllocatableProtocol: Memory.Region, ~Copyable {
    /// Consumes the region and wraps it as a passthrough `Memory.Allocator` — the whole region becomes
    /// one allocation. The default adopts `self` directly; a conformer overrides only if its adoption
    /// is non-trivial.
    consuming func makeAllocator() -> Memory.Allocator<Self>
}

extension __MemoryAllocatableProtocol where Self: ~Copyable {
    /// Default adoption: the passthrough over the whole region.
    @inlinable
    public consuming func makeAllocator() -> Memory.Allocator<Self> {
        Memory.Allocator(self)
    }
}
