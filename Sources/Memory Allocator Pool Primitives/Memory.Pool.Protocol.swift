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

public import Index_Primitives
public import Memory_Primitive

extension Memory.Pool {
    /// The law-bearing capability seam over a **fixed reusable slot universe**.
    ///
    /// ## Ontology
    ///
    /// - **Primitive**: slot identity (`Index<Memory.Pool.Slot>`).
    /// - **Derived**: address, base pointer, pointer arithmetic — observations computed
    ///   FROM a slot, never part of the algebra.
    /// - **Refinement**: a lifetime-stable region (heap conformers) strengthens L3's
    ///   borrow-scoped stability to whole-lifetime stability.
    ///
    /// This capability models **stable locations, not incarnations**: a freed-and-reused
    /// slot is the SAME location with new content. Incarnation identity (generation
    /// tokens) belongs to the ledger tier above (`Storage.Generational`), never here.
    ///
    /// ## Laws
    ///
    /// - **L1 — slot identity.** A slot allocated and not yet deallocated names one fixed
    ///   location for the allocation's lifetime; reuse after `deallocate` is lawful and
    ///   names the SAME location.
    /// - **L2 — slot geometry.** Slots have the size/alignment the pool was constructed
    ///   with, and distinct slots occupy disjoint regions. The affine layout (stride
    ///   arithmetic) is the MODEL's private realization — no arithmetic in the ontology.
    /// - **L3 — borrow-scoped address stability.** `pointer(at:)` for a live slot is
    ///   stable across operations on OTHER slots within a borrow scope of the pool.
    ///   Whole-lifetime stability is the heap-conformer refinement; generic code derives
    ///   the address PER ACCESS and NEVER caches it across moves of the pool.
    /// - **L4 — lifecycle totality.** `allocateSlot()` returns an unallocated slot or
    ///   throws exhaustion; `deallocate(at:)` of an allocated in-range slot CANNOT fail —
    ///   the `try!` license for callers who have proven liveness; double-free and
    ///   out-of-range throw.
    /// - **L5 — non-interference.** Operations on one slot do not observeably affect the
    ///   contents of other allocated slots.
    ///
    /// ## Why this seam exists (the §A15 language-gap record)
    ///
    /// `Storage.Generational`'s seam conformance was the ecosystem's only conditional
    /// conformance with a same-type `~Copyable` RHS
    /// (`where Allocation == Memory.Allocator<Memory.Heap>.Pool`) — a shape the Swift
    /// runtime cannot verify (catalog §A15, broken 6.2 → 6.5-dev; dossier in
    /// swift-institute/Issues). The protocol-bound respelling
    /// (`where Allocation: Memory.Pooling, Allocation: ~Copyable`) is the
    /// empirically-clean shape. The protocol is NOT an abstraction extracted for the
    /// workaround: `Memory.Allocator<Resource>.Pool` is ALREADY Resource-generic, so the
    /// quantifier is real — the defect merely forced the always-implicit slot-universe
    /// algebra to become explicit.
    ///
    /// ## Deletable convenience seam (the `Memory.Allocating` discipline)
    ///
    /// Use this seam ONLY for generic algorithms/extensions over any pool. Canonical
    /// spellings stay concrete
    /// (`Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element>` — unchanged
    /// everywhere); the existential `any`-form of `Memory.Pooling` NEVER. It MUST NOT refine into
    /// storage identity nor become the public spelling of pool products.
    ///
    /// ## Out of scope
    ///
    /// Relocating/compacting pools are a DIFFERENT algebra, not an extension of this one —
    /// future work must not weaken L1–L5 to accommodate hypothetical consumers.
    public protocol `Protocol`: ~Copyable {
        /// Observation: total slot capacity (as constructed; fixed for the pool's life).
        var capacity: Index<Memory.Pool.Slot>.Count { get }

        /// Observation: the slot's address, derived PER ACCESS (L3 — generic code never
        /// caches addresses across moves of the pool).
        ///
        /// - Precondition: `index < capacity`.
        @unsafe func pointer(at index: Index<Memory.Pool.Slot>) -> UnsafeMutableRawPointer

        /// Operation: claims an unallocated slot, or throws `.exhausted` (L4).
        mutating func allocateSlot() throws(Memory.Pool.Error) -> Index<Memory.Pool.Slot>

        /// Operation: returns an allocated in-range slot to the pool. For such a slot
        /// this CANNOT fail (L4 — the `try!` license); double-free/out-of-range throw.
        mutating func deallocate(at slot: Index<Memory.Pool.Slot>) throws(Memory.Pool.Error)
    }
}
