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

public import Memory_Address_Primitives
public import Memory_Alignment_Primitives
public import Memory_Allocation_Primitive
public import Memory_Allocator_Primitive
public import Memory_Primitive
public import Memory_Primitives_Standard_Library_Integration
public import Memory_Region_Primitives

// The Arena product is DECLARED here, from the Arena module, via a `where Resource: ~Copyable`
// extension on the generic `Memory.Allocator` (the cross-module nested-product mechanic — the
// explicit `where Resource: ~Copyable` keeps `Resource` non-`Copyable`; 6.3.2 mechanic #1).

extension Memory.Allocator where Resource: ~Copyable {
    /// A bump allocator over an element-free `Resource` region.
    ///
    /// Re-parameterization of the shipping `Memory.Allocator.Arena` (over a concrete
    /// `Memory.Heap`): the backing becomes the generic `Resource` region, read through the
    /// `Memory.Region` seam (`backing.base` / `backing.capacity`). O(1) bump allocation; no
    /// individual deallocation; bulk reclaim via `reset()` or the region's own `deinit`. Because the
    /// region is out-of-line with a stable base, vended addresses escape soundly.
    public struct Arena: ~Copyable {

        /// The backing region.
        ///
        /// The arena owns it; it frees on its own `deinit`.
        @usableFromInline internal var backing: Resource

        /// Bytes currently bumped from the region's base.
        @usableFromInline internal var cursor: Memory.Address.Count

        /// Creates an arena over an existing backing region.
        @inlinable
        public init(_ backing: consuming Resource) {
            self.backing = backing
            self.cursor = .zero
        }
    }
}

// MARK: - Properties

extension Memory.Allocator.Arena where Resource: ~Copyable {
    /// The start address of the arena's backing region (the Region seam — no raw pointer here).
    @inlinable
    public var start: Memory.Address { backing.base }

    /// The total capacity in bytes (the Region seam).
    @inlinable
    public var capacity: Memory.Address.Count { backing.capacity }

    /// The number of bytes currently allocated.
    @inlinable
    public var allocated: Memory.Address.Count { cursor }

    /// The number of bytes remaining.
    @inlinable
    public var remaining: Memory.Address.Count {
        capacity.subtract.saturating(cursor)
    }
}

// MARK: - Operations

extension Memory.Allocator.Arena where Resource: ~Copyable {
    /// Resets the arena, invalidating all previous allocations.
    @inlinable
    public mutating func reset() {
        cursor = .zero
    }
}

// MARK: - Sendable

/// Move-only owning absorber over a `Resource` region; unique ownership means cross-thread transfer
/// is a move that relinquishes the sender's access.
extension Memory.Allocator.Arena: @unchecked Sendable where Resource: ~Copyable & Sendable {}
