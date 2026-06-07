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
    /// A bump arena allocator over a fresh, fixed-capacity heap region.
    ///
    /// The factory parallel to `Iterator.repeating(_:)`: it names the strategy on the namespace and
    /// returns a concrete `Memory.Allocator.Arena` backed by the canonical stable, out-of-line
    /// region `Memory.Contiguous<Byte>`. The arena owns the region and reclaims it en masse via
    /// `reset()` or the region's `deinit`.
    ///
    /// - Parameter byteCapacity: Total capacity in bytes. Must be > 0.
    /// - Returns: A bump arena over a freshly-allocated heap region.
    @inlinable
    public static func arena(
        byteCapacity: Memory.Address.Count
    ) -> Memory.Allocator.Arena {
        // Allocate the out-of-line backing on the heap, 8-byte aligned, and hand
        // ownership to a self-owning `Memory.Contiguous<Byte>` (which frees on deinit).
        let count = Int(bitPattern: byteCapacity)
        let raw = unsafe UnsafeMutableRawPointer.allocate(
            count: byteCapacity,
            alignment: .`8`
        )
        let bytes = unsafe raw.bindMemory(to: Byte.self, capacity: count)
        let region = unsafe Memory.Contiguous<Byte>(adopting: bytes, count: count)
        return Memory.Allocator.Arena(region)
    }
}
