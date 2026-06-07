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

extension Memory.Allocator {
    /// A bump allocator for batch allocations over a heap byte region.
    ///
    /// Arena allocation provides:
    /// - O(1) allocation (bump pointer)
    /// - No individual deallocation overhead
    /// - Single bulk deallocation via `reset()`
    ///
    /// ## Backed by a stable, out-of-line region
    ///
    /// The arena holds a `Memory.Contiguous<Byte>` — a **stable, out-of-line**
    /// self-owning heap region — and bumps a `cursor` within its base address.
    /// Because the region is out of line and its base is stable, the addresses
    /// `allocate` vends *escape* soundly: they survive the arena value's moves.
    /// Build one via `Memory.Allocator.arena(byteCapacity:)`.
    ///
    /// The arena **owns** `backing`; the region frees itself on its own `deinit`,
    /// so the arena needs none.
    ///
    /// ## Invariants
    ///
    /// - `cursor` never exceeds the region's byte count
    // SAFETY: Encapsulates unsafe internals behind a safe API; see
    // SAFETY: [MEM-SAFE-024] for the absorber-pattern taxonomy.
    @safe
    public struct Arena: ~Copyable {
        /// The backing region. The arena owns it; it frees on its own `deinit`.
        @usableFromInline
        internal var backing: Memory.Contiguous<Byte>

        /// Bytes currently bumped from the region's base.
        @usableFromInline
        internal var cursor: Memory.Address.Count

        /// Creates an arena over an existing backing region.
        ///
        /// - Parameter backing: A stable, out-of-line heap byte region to bump within.
        @inlinable
        public init(_ backing: consuming Memory.Contiguous<Byte>) {
            self.backing = backing
            self.cursor = .zero
        }
    }
}

// MARK: - Properties

extension Memory.Allocator.Arena {
    /// The start address of the arena's backing region.
    @inlinable
    public var start: Memory.Address {
        // SAFETY: `unsafeBaseAddress` is valid for the lifetime of `backing`,
        // SAFETY: which the arena owns; the integer-address model carries no
        // SAFETY: provenance. See [MEM-SAFE-025a].
        unsafe Memory.Address(backing.unsafeBaseAddress)
    }

    /// The total capacity in bytes.
    ///
    /// `Byte` has stride 1, so the region's byte count equals its element count.
    @inlinable
    public var capacity: Memory.Address.Count { Memory.Address.Count(UInt(backing.count)) }

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

extension Memory.Allocator.Arena {
    /// Resets the arena, invalidating all previous allocations.
    ///
    /// - Warning: All addresses from this arena become invalid.
    @inlinable
    public mutating func reset() {
        cursor = .zero
    }

    /// Allocates memory from the arena (the ``Memory/Allocator/Protocol`` seam).
    ///
    /// - Parameters:
    ///   - count: Number of bytes to allocate.
    ///   - alignment: Required alignment (power of 2).
    /// - Returns: Address to allocated memory.
    /// - Throws: ``Memory/Allocator/Arena/Error/insufficientCapacity(requested:available:)`` where
    ///   the bump pointer would overflow the arena — the typed-error edge of the former `Optional`
    ///   return.
    @inlinable
    public mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) throws(Memory.Allocator.Arena.Error) -> Memory.Address {
        let capacity = self.capacity

        // Round up the cursor to the alignment boundary.
        let alignedCursor = alignment.align.up(cursor)

        // Check if allocation fits (overflow-safe).
        guard let endCursor = try? alignedCursor.add.exact(count),
            endCursor <= capacity
        else {
            throw .insufficientCapacity(
                requested: count,
                available: (try? capacity.subtract.exact(alignedCursor)) ?? .zero
            )
        }

        // Update the cursor.
        cursor = endCursor

        // Return the allocated address: base advanced by the aligned cursor.
        // SAFETY: `alignedCursor <= capacity`, the region's byte count, so the
        // SAFETY: advanced pointer stays within the owned region; the region is
        // SAFETY: out-of-line and stable, so the address escapes soundly.
        // SAFETY: See [MEM-SAFE-025a].
        return unsafe Memory.Address(
            start.mutablePointer.advanced(
                by: Memory.Address.Offset(alignedCursor)
            )
        )
    }

    /// Deallocates previously-allocated memory — a **no-op** for a bump allocator.
    ///
    /// `Memory.Allocator.Arena` reclaims storage only en masse via ``reset()`` (or the backing
    /// region's `deinit`); individual deallocation is not part of its discipline. The
    /// ``Memory/Allocator/Protocol`` requirement is satisfied trivially so the arena composes as a
    /// `Memory.Allocator`.
    @inlinable
    public mutating func deallocate(
        _ address: Memory.Address,
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) {
        // Bump allocator: no per-allocation free; storage is reclaimed by `reset()` / region `deinit`.
    }
}

// MARK: - Memory.Allocator.Protocol

/// `Memory.Allocator.Arena` is a bump `Memory.Allocator` — it vends aligned addresses out of a
/// stable, out-of-line backing region and reclaims them en masse. Conforming the canonical allocator
/// seam (`allocate(count:alignment:) throws -> Memory.Address` / `deallocate`) lets it stand wherever
/// a `Memory.Allocator.\`Protocol\`` is required.
extension Memory.Allocator.Arena: Memory.Allocator.`Protocol` {}

// MARK: - Sendable

/// Sendable conformance for `Memory.Allocator.Arena`.
///
/// ## Safety Invariant
///
/// `Memory.Allocator.Arena` is `struct ~Copyable` owning a `Memory.Contiguous<Byte>` region (which
/// itself owns the out-of-line storage and frees it on `deinit`). The encapsulation invariant is
/// asserted by the adjacent `// SAFETY:` comment per [MEM-SAFE-025a]; the `@safe` attribute is
/// forbidden in `Sources/` per [MEM-SAFE-025b]. Unique ownership guarantees at most one thread
/// accesses the bump cursor at any time; cross-thread transfer via move relinquishes the sender's
/// access.
///
/// ## Non-Goals
///
/// - Not a shared allocator — arena is single-owner by construction.
/// - Addresses returned by `allocate(count:alignment:)` are not themselves Sendable independently of
///   the arena.
extension Memory.Allocator.Arena: @unsafe @unchecked Sendable {}
