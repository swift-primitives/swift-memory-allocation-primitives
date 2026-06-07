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

// MARK: - Memory.Allocator.Protocol

/// `Memory.Allocator.Pool` is a free-list `Memory.Allocator`. Conforming the canonical allocator
/// seam (`allocate(count:alignment:) throws -> Memory.Address` / `deallocate`) lets the pool stand
/// wherever a `Memory.Allocator.\`Protocol\`` is required, alongside `Memory.Allocator.Arena` (bump)
/// and the system witness.
///
/// Pool is a **fixed-slot** allocator: every allocation is one `slotStride`-byte,
/// `slotAlignment`-aligned slot. The allocator-protocol `count`/`alignment` are therefore a *fit
/// contract* — a request that exceeds a slot, or needs stronger alignment than the slots provide,
/// is outside this pool's discipline (use `Memory.Allocator.Arena` for variable-size requests).
extension Memory.Allocator.Pool: Memory.Allocator.`Protocol` {
    /// Allocates one slot and returns its address (the ``Memory/Allocator/Protocol`` seam).
    ///
    /// - Parameters:
    ///   - count: Requested byte count — must fit a slot (`<= slotStride`) by the fixed-slot contract.
    ///   - alignment: Requested alignment — satisfied for `<= slotAlignment` by the fixed-slot contract.
    /// - Returns: The address of a freshly-allocated slot.
    /// - Throws: ``Memory/Allocator/Pool/Error/exhausted(capacity:)`` when no free slot remains.
    @inlinable
    public mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) throws(Memory.Allocator.Pool.Error) -> Memory.Address {
        let pointer = try allocate()
        return unsafe Memory.Address(pointer)
    }

    /// Returns the slot at `address` to the free list (the ``Memory/Allocator/Protocol`` seam).
    ///
    /// Non-throwing per the protocol: a foreign or already-freed address is a programming error and
    /// is dropped (the throwing `deallocate(_:)` remains available for checked callers).
    @inlinable
    public mutating func deallocate(
        _ address: Memory.Address,
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) {
        try? deallocate(unsafe UnsafeMutableRawPointer(address))
    }
}
