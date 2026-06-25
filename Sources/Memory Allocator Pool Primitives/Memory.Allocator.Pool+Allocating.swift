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
public import Memory_Allocator_Protocol_Primitives
public import Memory_Primitive

// `Memory.Allocator.Pool` is a free-list `Memory.Allocating`. Conforming the canonical seam lets the
// pool stand wherever a `Memory.Allocating` is required. Pool is a FIXED-SLOT allocator: every
// allocation is one `slotStride`-byte, `slotAlignment`-aligned slot, so `count`/`alignment` are a
// fit contract.

extension Memory.Allocator.Pool: Memory.Allocator.`Protocol` where Resource: ~Copyable {
    /// Allocates one slot and returns its address (the seam).
    @inlinable
    public mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) throws(Error) -> Memory.Address {
        // SAFETY: `allocate()` vends a pool-owned slot pointer; wrap it into the integer-address model.
        let pointer = unsafe try allocate()
        return unsafe Memory.Address(pointer)
    }

    /// Returns the slot at `address` to the free list (the seam).
    ///
    /// Non-throwing: a foreign or already-freed address is a programming error and is dropped.
    @inlinable
    public mutating func deallocate(
        _ address: Memory.Address,
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) {
        // SAFETY: recovering the raw pointer from the integer-address model to return the slot.
        do throws(Error) {
            unsafe try deallocate(UnsafeMutableRawPointer(address))
        } catch {
            // A foreign or already-freed address is a programming error; the seam's non-throwing
            // contract drops it ([IMPL-108]/[IMPL-075]: explicit typed catch over silent `try?`).
        }
    }
}
