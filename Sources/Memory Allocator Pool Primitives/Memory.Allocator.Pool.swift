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

public import Affine_Discrete_Primitives
public import Bit_Vector_Primitives
public import Index_Primitives
public import Memory_Alignment_Primitives
public import Memory_Allocator_Primitive
public import Memory_Primitive

// The Pool product is DECLARED here, from the Pool module, via a `where Resource: ~Copyable`
// extension on the generic `Memory.Allocator` (declared in the Primitive module). The explicit
// `where Resource: ~Copyable` clause is load-bearing: a bare extension re-defaults the enclosing
// generic to `Copyable`, hiding the nested type for a non-`Copyable` `Resource` (6.3.2 mechanic #1).
// Cross-module nested-product declaration with `Resource` staying non-`Copyable` is proven on 6.3.2.

extension Memory.Allocator where Resource: ~Copyable {
    /// A fixed-slot allocator with O(1) allocate/deallocate via an in-band free list, over a
    /// `Resource` region.
    ///
    /// Re-parameterization of the shipping non-generic `Memory.Allocator.Pool` (over a concrete
    /// `Memory.Heap`). Every rich invariant is preserved, with the single faithful change
    /// that the backing is now the generic element-free `Resource` region:
    /// - `Bit.Vector` occupancy bitmap → **double-free detection** (independent of slot content).
    /// - typed-throws `Pool.Error` (aliased to the non-generic `Memory.Pool.Error`).
    /// - typed slot geometry: `Affine.Discrete.Ratio<Slot, Memory>` stride + `Memory.Alignment`.
    /// - typed `Index<Slot>` raw slot identity — the allocator exposes `Index<Slot>`, **never**
    ///   `Index<Element>` (Storage lifts that one tier up).
    /// - in-band free list (a freed slot stores the next free `Index<Slot>` in its own memory) +
    ///   O(1) virgin cursor.
    public struct Pool: ~Copyable {
        /// Phantom tag for slot-level indexing within a pool.
        ///
        /// Aliased to the NON-generic `Memory.Pool.Slot` (a Resource-independent concept — must not be
        /// phantom-generic over `Resource`; see `Memory.Pool`, the algebra home).
        public typealias Slot = Memory.Pool.Slot

        /// The pool's typed errors — aliased to the NON-generic `Memory.Pool.Error`.
        public typealias Error = Memory.Pool.Error

        // MARK: - Stored Properties

        /// The backing region.
        ///
        /// The pool owns it; it frees on its own `deinit`.
        @usableFromInline internal var backing: Resource

        /// Scaling factor from slot domain to byte domain.
        @usableFromInline internal let _slotStride: Affine.Discrete.Ratio<Slot, Memory>

        /// Alignment requirement for each slot (cannot be recovered from stride).
        @usableFromInline internal let _slotAlignment: Memory.Alignment

        /// Total number of slots.
        @usableFromInline internal let _capacity: Index<Slot>.Count

        /// Number of currently allocated (in-use) slots.
        @usableFromInline internal var _allocated: Index<Slot>.Count

        /// Head of the free list.
        ///
        /// Equal to the sentinel (one-past-last) when empty.
        @usableFromInline internal var _freeHead: Index<Slot>

        /// Next virgin (never-used) slot.
        ///
        /// Advances monotonically from `.zero` to sentinel.
        @usableFromInline internal var _nextUnused: Index<Slot>

        /// Tracks which slots are currently allocated, for double-free detection.
        @usableFromInline internal var _allocationBits: Bit.Vector

        /// Adopts an existing, correctly-sized backing region plus pre-computed slot geometry.
        @inlinable
        public init(
            adopting backing: consuming Resource,
            slotStride: Affine.Discrete.Ratio<Slot, Memory>,
            slotAlignment: Memory.Alignment,
            capacity: Index<Slot>.Count,
            allocated: Index<Slot>.Count,
            freeHead: Index<Slot>,
            nextUnused: Index<Slot>,
            allocationBits: consuming Bit.Vector
        ) {
            self.backing = backing
            self._slotStride = slotStride
            self._slotAlignment = slotAlignment
            self._capacity = capacity
            self._allocated = allocated
            self._freeHead = freeHead
            self._nextUnused = nextUnused
            self._allocationBits = allocationBits
        }
    }
}
