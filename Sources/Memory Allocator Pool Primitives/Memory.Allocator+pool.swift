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
    /// A fixed-slot free-list pool allocator over a fresh heap region.
    ///
    /// The factory parallel to `Iterator.repeating(_:)`: it names the strategy on the namespace and
    /// returns a concrete `Memory.Allocator.Pool` backed by the canonical stable, out-of-line region
    /// `Memory.Contiguous<Byte>`. The pool owns its backing region and reclaims it en masse via
    /// `reset()` or the region's `deinit`; individual slots are reclaimed via `deallocate`.
    ///
    /// - Parameters:
    ///   - slotSize: Size of each slot in bytes. Must be ≥ `MemoryLayout<Index<Pool.Slot>>.size`.
    ///   - slotAlignment: Required alignment per slot.
    ///   - capacity: Number of slots. Must be > 0.
    /// - Returns: A free-list pool over a freshly-allocated heap region.
    /// - Throws: ``Memory/Allocator/Pool/Error`` if the slot geometry or capacity is invalid.
    @inlinable
    public static func pool(
        slotSize: Memory.Address.Count,
        slotAlignment: Memory.Alignment,
        capacity: Index<Memory.Allocator.Pool.Slot>.Count
    ) throws(Memory.Allocator.Pool.Error) -> Memory.Allocator.Pool {
        try Memory.Allocator.Pool(
            slotSize: slotSize,
            slotAlignment: slotAlignment,
            capacity: capacity
        )
    }
}
