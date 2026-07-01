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

public import Memory_Allocator_Protocol_Primitives

/// `Memory.Allocator.Arena` is a bump `Memory.Allocating` — it vends aligned addresses out of a
/// stable, out-of-line backing region and reclaims them en masse. Its inherent
/// `allocate(count:alignment:)` / `deallocate` already match the seam, so the conformance is a
/// declaration only.
extension Memory.Allocator.Arena: Memory.Allocator.`Protocol` where Resource: ~Copyable {
    /// Allocates `count` aligned bytes by bumping the cursor (the `Memory.Allocating` seam).
    ///
    /// - Throws: `.insufficientCapacity` where the bump pointer would overflow the arena.
    @inlinable
    public mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) throws(Self.Error) -> Memory.Address {
        let capacity = self.capacity

        // Round up the cursor to the alignment boundary.
        let alignedCursor = alignment.align.up(cursor)

        // Check if allocation fits (overflow-safe).
        // swiftlint:disable:next no_try_optional - reason: deliberate overflow probe; a nil (Cardinal.Error.overflow) IS the does-not-fit signal routed to the .insufficientCapacity throw below
        guard let endCursor = try? alignedCursor.add.exact(count),
            endCursor <= capacity
        else {
            throw .insufficientCapacity(
                requested: count,
                // swiftlint:disable:next no_try_optional - reason: deliberate underflow probe; a nil (Cardinal.Error.underflow) means no remaining capacity, meaningfully reported as .zero
                available: (try? capacity.subtract.exact(alignedCursor)) ?? .zero
            )
        }

        // Update the cursor.
        cursor = endCursor

        // Return the allocated address: base advanced by the aligned cursor.
        // SAFETY: `alignedCursor <= capacity`, the region's byte count, so the advanced pointer stays
        // SAFETY: within the owned region; the region is out-of-line and stable, so the address
        // SAFETY: escapes soundly. See [MEM-SAFE-025a].
        return unsafe Memory.Address(
            start.mutablePointer.advanced(
                by: Memory.Address.Offset(alignedCursor)
            )
        )
    }

    /// Deallocates previously-allocated memory — a **no-op** for a bump allocator.
    @inlinable
    public mutating func deallocate(
        _ address: Memory.Address,
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) {
        // Bump allocator: no per-allocation free; storage is reclaimed by `reset()` / region `deinit`.
    }
}
