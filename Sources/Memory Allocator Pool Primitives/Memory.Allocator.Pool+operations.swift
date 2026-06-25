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
public import Memory_Address_Primitives
public import Memory_Alignment_Primitives
public import Memory_Allocator_Primitive
public import Memory_Primitive
public import Memory_Primitives_Standard_Library_Integration
public import Memory_Region_Primitives

// MARK: - Region-carving construction (any `Resource` — e.g. Memory.Inline<n>)

extension Memory.Allocator.Pool where Resource: ~Copyable {
    /// Creates a pool that carves fixed slots **within an existing** `Resource` region.
    ///
    /// The region's `capacity` bounds the slot count. This is the constructor for a
    /// `Memory.Inline<n>`-backed pool (the inline bytes already exist) and any other pre-allocated
    /// region; the heap-backed `init(slotSize:slotAlignment:capacity:)` instead *allocates* a region
    /// sized to the capacity.
    ///
    /// - Throws: `.slotSizeTooSmall` if a slot can't hold the in-band free-list link; `.invalidCapacity`
    ///   if the region holds fewer than one slot.
    @inlinable
    public init(
        carving backing: consuming Resource,
        slotSize: Memory.Address.Count,
        slotAlignment: Memory.Alignment
    ) throws(Error) {
        let minimumSlotSize = Memory.Address.Count(UInt(MemoryLayout<Index<Slot>>.size))
        guard slotSize >= minimumSlotSize else {
            throw .slotSizeTooSmall(requested: slotSize, minimum: minimumSlotSize)
        }

        let slotStride = Affine.Discrete.Ratio<Slot, Memory>(slotAlignment.align.up(slotSize))
        // Number of whole slots that fit in the region's byte capacity (Region seam).
        let (capacity, _) = slotStride.quotientAndRemainder(dividing: backing.capacity)
        guard capacity > .zero else {
            throw .invalidCapacity
        }

        self.init(
            adopting: backing,
            slotStride: slotStride,
            slotAlignment: slotAlignment,
            capacity: capacity,
            allocated: .zero,
            freeHead: capacity.map(Ordinal.init),  // sentinel
            nextUnused: .zero,
            allocationBits: Bit.Vector(capacity: capacity.retag(Bit.self))
        )
    }
}

// MARK: - Base Address / Pointer Primitive / Sentinel

extension Memory.Allocator.Pool where Resource: ~Copyable {
    /// The stable base address of the backing region's first byte.
    @inlinable
    internal var _base: Memory.Address { backing.base }

    /// Returns the pointer to the slot at the given index (no bounds check).
    @inlinable
    internal func _pointer(at index: Index<Slot>) -> UnsafeMutableRawPointer {
        // SAFETY: `index` is bounded by callers; `mutablePointer` is the region's escape hatch.
        unsafe _base.mutablePointer.advanced(
            by: Index<Slot>.Offset(fromZero: index) * _slotStride
        )
    }

    /// The end-of-list sentinel: one-past-last valid slot index (analogous to `endIndex`).
    @inlinable
    internal var _sentinel: Index<Slot> { _capacity.map(Ordinal.init) }
}

// MARK: - Properties

extension Memory.Allocator.Pool where Resource: ~Copyable {
    /// Total number of slots.
    @inlinable
    public var capacity: Index<Slot>.Count { _capacity }

    /// Number of currently allocated (in-use) slots.
    @inlinable
    public var allocated: Index<Slot>.Count { _allocated }

    /// Number of free slots remaining.
    @inlinable
    public var available: Index<Slot>.Count {
        _capacity.subtract.saturating(_allocated)
    }

    /// Whether all slots are allocated (no free or virgin slots remain).
    @inlinable
    public var isExhausted: Bool {
        _freeHead == _sentinel && _nextUnused >= _sentinel
    }
}

// MARK: - Index-Based Operations

extension Memory.Allocator.Pool where Resource: ~Copyable {
    /// Allocates a slot and returns its index.
    ///
    /// Prefers freed slots (free list), then virgin cursor.
    ///
    /// - Throws: `.exhausted` if no free or virgin slots remain.
    /// - Complexity: O(1)
    @inlinable
    public mutating func allocateSlot() throws(Error) -> Index<Slot> {
        // Try free list first (reused slots).
        if _freeHead != _sentinel {
            let slot = _freeHead
            // SAFETY: a freed slot holds the next free `Index<Slot>` in its own bytes (in-band list).
            _freeHead = unsafe _pointer(at: slot).load(as: Index<Slot>.self)
            _allocationBits[slot.retag(Bit.self)] = true
            _allocated += .one
            return slot
        }

        // Try virgin cursor.
        guard _nextUnused < _sentinel else {
            throw .exhausted(capacity: _capacity)
        }

        let slot = _nextUnused
        _nextUnused += .one
        _allocationBits[slot.retag(Bit.self)] = true
        _allocated += .one
        return slot
    }

    /// Returns a slot to the free list by index.
    ///
    /// - Throws: `.doubleFree` if the slot is already free.
    /// - Complexity: O(1)
    @inlinable
    public mutating func deallocate(at slot: Index<Slot>) throws(Error) {
        let bitIndex = slot.retag(Bit.self)
        guard _allocationBits[bitIndex] else {
            throw .doubleFree
        }

        // Clear allocation bit.
        _allocationBits[bitIndex] = false

        // Push current head into this slot, make slot new head (LIFO).
        // SAFETY: writing the in-band free-list link into the freed slot's own bytes.
        unsafe _pointer(at: slot).storeBytes(of: _freeHead, as: Index<Slot>.self)
        _freeHead = slot
        _allocated = _allocated.subtract.saturating(.one)
    }
}

// MARK: - Pointer-Based Operations

extension Memory.Allocator.Pool where Resource: ~Copyable {
    /// Allocates a slot and returns a pointer to its (uninitialized) memory.
    @inlinable
    public mutating func allocate() throws(Error) -> UnsafeMutableRawPointer {
        unsafe try _pointer(at: allocateSlot())
    }

    /// Returns a slot to the free list by pointer.
    ///
    /// - Throws: `.foreignPointer` if the pointer does not belong to this pool; `.doubleFree` if free.
    @inlinable
    public mutating func deallocate(_ pointer: UnsafeMutableRawPointer) throws(Error) {
        guard let slot = unsafe index(for: pointer) else {
            throw .foreignPointer
        }
        try deallocate(at: slot)
    }

    /// Returns all slots to the free list.
    ///
    /// All previously returned pointers become invalid.
    ///
    /// - Complexity: O(n/64) (clear bits only).
    @inlinable
    public mutating func reset() {
        _freeHead = _sentinel
        _nextUnused = .zero
        _allocated = .zero
        _allocationBits.clear.all()
    }
}

// MARK: - Slot Address Queries

extension Memory.Allocator.Pool where Resource: ~Copyable {
    /// Returns the pointer to the slot at the given index.
    /// - Precondition: `index < capacity`.
    @inlinable
    public func pointer(at index: Index<Slot>) -> UnsafeMutableRawPointer {
        precondition(index < _capacity, "Slot index out of bounds")
        return unsafe _pointer(at: index)
    }

    /// Returns the slot index for a pointer previously returned by `allocate()`, or `nil` if foreign.
    @inlinable
    public func index(for pointer: UnsafeMutableRawPointer) -> Index<Slot>? {
        // SAFETY: pointer arithmetic against the pool's own base to recover the slot identity.
        let rawOffset = unsafe pointer - _base.mutablePointer
        guard rawOffset >= 0 else { return nil }

        let byteCount = Memory.Address.Count(UInt(rawOffset))
        guard byteCount < _capacity * _slotStride else { return nil }

        let (slotCount, remainder) = _slotStride.quotientAndRemainder(dividing: byteCount)
        guard remainder == .zero else { return nil }

        return slotCount.map(Ordinal.init)
    }
}

// MARK: - Sendable

/// `Memory.Allocator.Pool` is a move-only owning absorber: unique ownership guarantees at most one
/// thread mutates pool state; cross-thread transfer via move relinquishes the sender's access.
extension Memory.Allocator.Pool: @unchecked Sendable where Resource: ~Copyable & Sendable {}
