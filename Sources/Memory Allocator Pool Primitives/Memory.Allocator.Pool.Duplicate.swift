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

// `duplicate` allocates a *fresh* backing region of the same geometry — a new self-owning
// `Memory.Contiguous<Byte>` — and copies the live slot contents into it.
extension Memory.Allocator.Pool {
    /// Creates a deep copy of this pool's backing storage.
    ///
    /// Iterates slots below `_nextUnused`:
    /// - Allocated slots: calls `copySlotContents` with (source, destination) raw pointers
    /// - Freed slots: raw-copies the in-band free list link bytes
    ///
    /// The caller is responsible for performing type-correct copies via the closure.
    ///
    /// - Parameter copySlotContents: Closure called for each allocated slot.
    ///   Receives (source, destination) raw pointers. The closure must copy
    ///   the typed content from source to destination.
    /// - Returns: A new pool with identical slot layout and allocation state.
    @inlinable
    public func duplicate(
        copySlotContents: (
            _ source: UnsafeMutableRawPointer,
            _ destination: UnsafeMutableRawPointer
        ) -> Void
    ) -> Memory.Allocator.Pool {
        // Allocate new backing storage with same geometry, owned by a fresh heap region.
        let byteCount = _capacity * _slotStride
        let newRaw = unsafe UnsafeMutableRawPointer.allocate(
            count: byteCount,
            alignment: _slotAlignment
        )
        let newBytes = unsafe newRaw.bindMemory(to: Byte.self, capacity: Int(bitPattern: byteCount))
        let newRegion = unsafe Memory.Contiguous<Byte>(
            adopting: newBytes,
            count: Int(bitPattern: byteCount)
        )
        // SAFETY: `unsafeBaseAddress` is valid for the lifetime of `newRegion`,
        // SAFETY: which this scope owns until it is moved into the returned pool;
        // SAFETY: the integer-address model carries no provenance. See [MEM-SAFE-025a].
        let newBase = unsafe Memory.Address(newRegion.unsafeBaseAddress).mutablePointer

        // Copy used region (bounded by virgin cursor).
        var slot: Index<Slot> = .zero
        while slot < _nextUnused {
            let srcPointer = unsafe _pointer(at: slot)
            let dstPointer = unsafe newBase.advanced(
                by: Index<Slot>.Offset(fromZero: slot) * _slotStride
            )

            if _allocationBits[slot.retag(Bit.self)] {
                // Allocated slot: call closure for type-correct copy.
                unsafe copySlotContents(srcPointer, dstPointer)
            } else {
                // Freed slot: raw-copy the in-band free list link.
                unsafe dstPointer.storeBytes(
                    of: srcPointer.load(as: Index<Slot>.self),
                    as: Index<Slot>.self
                )
            }
            // Safe: loop guard `slot < _nextUnused` ensures +1 cannot overflow.
            slot = try! slot + .one
        }

        // Duplicate allocation bits.
        let newBits = Bit.Vector(capacity: _capacity.retag(Bit.self))
        unsafe _allocationBits.withUnsafeWords { srcWords in
            unsafe newBits.withUnsafeMutableWords { dstWords in
                for i in 0..<srcWords.count {
                    unsafe dstWords[i] = srcWords[i]
                }
            }
        }

        return unsafe Memory.Allocator.Pool(
            adopting: newRegion,
            slotStride: _slotStride,
            slotAlignment: _slotAlignment,
            capacity: _capacity,
            allocated: _allocated,
            freeHead: _freeHead,
            nextUnused: _nextUnused,
            allocationBits: newBits
        )
    }
}
