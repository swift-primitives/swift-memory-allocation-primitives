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
public import Memory_Primitive
public import Memory_Region_Primitives

extension Memory {
    /// The allocator layer: a carve/recycle policy over an element-free `Resource` region.
    ///
    /// `Memory.Allocator<Resource>` is the operation-domain **agent noun** and **the witness** of the
    /// allocation capability. A *bare* `Memory.Allocator<Resource>` is the **passthrough** allocator —
    /// it adopts the whole resource as one allocation and forwards its base (the role the prior
    /// `Memory.Allocator.System` struct played; now absorbed into the agent noun itself). The named
    /// strategies `Pool` (fixed-slot free list) and `Arena` (bump) are sibling concrete conformers,
    /// declared from their own modules via `extension Memory.Allocator where Resource: ~Copyable { … }`
    /// — the cross-module nested-product mechanic (the explicit `where Resource: ~Copyable` clause
    /// preserves the non-`Copyable` `Resource`; proven on 6.3.2). `Slab` is reserved (not yet
    /// materialized).
    ///
    /// The allocate/deallocate capability seam is hosted ON this agent noun as the canonical triple:
    /// `Memory.Allocator` / `Memory.Allocator.\`Protocol\`` / `Memory.Allocating`. A protocol cannot
    /// nest in a generic type on 6.3.2, so it is hoisted to module scope as `__MemoryAllocatorProtocol`
    /// and re-exposed via a param-free `typealias \`Protocol\`` ([API-IMPL-009] / [API-IMPL-023]).
    ///
    /// The passthrough's failure channel is `Never`: it adopts a fixed region and traps on an
    /// over-capacity request (the `Memory.Allocator.system` witness's prior `Never` failure channel).
    public struct Allocator<Resource: ~Copyable & Memory.Region>: ~Copyable {
        /// The adopted resource region.
        ///
        /// The passthrough owns it; it frees on its own `deinit`.
        @usableFromInline
        internal var resource: Resource

        /// Creates a passthrough allocator that adopts the whole `resource` region as one allocation.
        @inlinable
        public init(_ resource: consuming Resource) {
            self.resource = resource
        }
    }
}

// MARK: - Region (passthrough — forwards the Region seam to its resource)

extension Memory.Allocator: Memory.Region where Resource: ~Copyable {
    /// The base address of the adopted resource region.
    @inlinable
    public var base: Memory.Address { resource.base }

    /// The byte capacity of the adopted resource region.
    @inlinable
    public var capacity: Memory.Address.Count { resource.capacity }
}

// MARK: - Sendable

/// Move-only owning passthrough over a `Resource` region; unique ownership means cross-thread transfer
/// is a move that relinquishes the sender's access.
extension Memory.Allocator: @unchecked Sendable where Resource: ~Copyable & Sendable {}
