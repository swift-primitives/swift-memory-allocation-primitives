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
    /// A fixed-slot allocator with O(1) allocate and deallocate via in-band free list,
    /// over a heap byte region.
    ///
    /// Pool allocation provides:
    /// - O(1) allocation (virgin cursor or free list pop)
    /// - O(1) deallocation (push to free list)
    /// - Per-slot reuse (unlike Arena, which only supports bulk reset)
    /// - Zero fragmentation (all slots are the same size)
    ///
    /// ## Backed by a stable, out-of-line region
    ///
    /// The pool holds a `Memory.Contiguous<Byte>` — a **stable, out-of-line**
    /// self-owning heap region — and lays its fixed slots out within its base
    /// address. Because the region is out of line and its base is stable, the
    /// addresses `allocate` vends *escape* soundly. Build one via
    /// `Memory.Allocator.pool(slotSize:slotAlignment:capacity:)`.
    /// The pool **owns** `backing`; the region frees itself on its own `deinit`.
    ///
    /// ## Invariants
    ///
    /// - Slot size ≥ `MemoryLayout<Index<Slot>>.size` (in-band free list storage)
    /// - Slot alignment is power of 2
    /// - Capacity is fixed at construction, immutable
    /// - `0 ≤ allocated ≤ capacity`
    /// - Free list is acyclic and contained within `[0, _nextUnused)`
    /// - Every address returned by `allocate()` belongs to this pool's backing region
    /// - `capacity * slotStride <= ` the region's byte count
    ///
    /// ## Free List Design
    ///
    /// Free slots store the `Index<Slot>` of the next free slot in-band (at the
    /// slot's own memory location) via `storeBytes(of:as:)` / `load(as:)`. The
    /// sentinel value `_sentinel` (one-past-last, analogous to `endIndex`) marks
    /// end-of-list. No raw value extraction is needed — the typed index flows
    /// directly through memory operations.
    ///
    /// Virgin slots (never allocated) are tracked by `_nextUnused` cursor,
    /// providing O(1) initialization (no free list pre-build).
    ///
    /// A separate `Bit.Vector` tracks which slots are allocated, enabling correct
    /// double-free detection even when consumers store typed content in allocated
    /// slots.
    ///
    /// ## Typed Access
    ///
    /// Pool operates on untyped bytes. Typed access is composed at the call site:
    ///
    /// ```swift
    /// var pool = try Memory.Allocator.Pool(slotSize: ..., slotAlignment: ..., capacity: ...)
    /// let slot = try pool.allocateSlot()
    /// let pointer = pool.pointer(at: slot).assumingMemoryBound(to: Node.self)
    /// pointer.initialize(to: node)
    /// // ... use ...
    /// _ = pointer.move()
    /// try pool.deallocate(at: slot)
    /// ```
    // SAFETY: Encapsulates unsafe internals behind a safe API; see
    // SAFETY: [MEM-SAFE-024] for the absorber-pattern taxonomy.
    @safe
    public struct Pool: ~Copyable {

        // MARK: - Stored Properties

        /// The backing region. The pool owns it; it frees on its own `deinit`.
        @usableFromInline
        internal var backing: Memory.Contiguous<Byte>

        /// Scaling factor from slot domain to byte domain.
        @usableFromInline
        internal let _slotStride: Affine.Discrete.Ratio<Slot, Memory>

        /// Alignment requirement for each slot (cannot be recovered from stride).
        @usableFromInline
        internal let _slotAlignment: Memory.Alignment

        /// Total number of slots.
        @usableFromInline
        internal let _capacity: Index<Slot>.Count

        /// Number of currently allocated (in-use) slots.
        @usableFromInline
        internal var _allocated: Index<Slot>.Count

        /// Head of the free list (previously used then freed slots).
        /// Equal to `_sentinel` when no freed slots are available.
        ///
        /// This is a typed `Index<Slot>`, not an Optional. The sentinel
        /// value (`_capacity.map(Ordinal.init)`, one-past-last) represents
        /// end-of-list — analogous to `endIndex` in Swift collections.
        @usableFromInline
        internal var _freeHead: Index<Slot>

        /// Next virgin (never-used) slot. Advances monotonically from `.zero` to sentinel.
        /// Provides O(1) init by deferring free list construction.
        @usableFromInline
        internal var _nextUnused: Index<Slot>

        /// Tracks which slots are currently allocated for double-free detection.
        @usableFromInline
        internal var _allocationBits: Bit.Vector

        /// Adopts an existing, correctly-sized backing region plus pre-computed slot geometry.
        ///
        /// This is the designated initializer; the convenience
        /// `init(slotSize:slotAlignment:capacity:)` sizes and allocates the region before
        /// delegating here.
        ///
        /// - Precondition: `capacity * slotStride <= ` the region's byte count.
        @inlinable
        public init(
            adopting backing: consuming Memory.Contiguous<Byte>,
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

// MARK: - Heap-backed construction

extension Memory.Allocator.Pool {
    /// Creates a pool with the specified slot geometry and capacity over a fresh heap region.
    ///
    /// All slots start uninitialized. Uses O(1) virgin cursor initialization
    /// instead of O(n) free list pre-build. The pool allocates and owns a
    /// `Memory.Contiguous<Byte>` of exactly `capacity * slotStride` bytes.
    ///
    /// - Parameters:
    ///   - slotSize: Size of each slot in bytes. Must be ≥ `MemoryLayout<Index<Slot>>.size`.
    ///   - slotAlignment: Required alignment per slot.
    ///   - capacity: Number of slots. Must be > 0.
    /// - Throws: `Pool.Error` if parameters are invalid.
    @inlinable
    public init(
        slotSize: Memory.Address.Count,
        slotAlignment: Memory.Alignment,
        capacity: Index<Slot>.Count
    ) throws(Memory.Allocator.Pool.Error) {
        guard capacity > .zero else {
            throw .invalidCapacity
        }

        let minimumSlotSize = Memory.Address.Count(UInt(MemoryLayout<Index<Slot>>.size))
        guard slotSize >= minimumSlotSize else {
            throw .slotSizeTooSmall(
                requested: slotSize,
                minimum: minimumSlotSize
            )
        }

        let slotStride = Affine.Discrete.Ratio<Slot, Memory>(slotAlignment.align.up(slotSize))

        // Allocate the out-of-line backing on the heap, sized to hold every slot,
        // and hand ownership to a self-owning `Memory.Contiguous<Byte>`.
        let byteCount = capacity * slotStride
        let raw = unsafe UnsafeMutableRawPointer.allocate(
            count: byteCount,
            alignment: slotAlignment
        )
        let bytes = unsafe raw.bindMemory(to: Byte.self, capacity: Int(bitPattern: byteCount))
        let region = unsafe Memory.Contiguous<Byte>(
            adopting: bytes,
            count: Int(bitPattern: byteCount)
        )

        self.init(
            adopting: region,
            slotStride: slotStride,
            slotAlignment: slotAlignment,
            capacity: capacity,
            allocated: .zero,
            // O(1) initialization via virgin cursor — no free list pre-build.
            freeHead: capacity.map(Ordinal.init),  // sentinel
            nextUnused: .zero,
            allocationBits: Bit.Vector(capacity: capacity.retag(Bit.self))
        )
    }
}

// MARK: - Base Address

extension Memory.Allocator.Pool {
    /// The stable base address of the backing region's first byte.
    @inlinable
    internal var _baseAddress: Memory.Address {
        // SAFETY: `unsafeBaseAddress` is valid for the lifetime of `backing`,
        // SAFETY: which the pool owns; the integer-address model carries no
        // SAFETY: provenance. See [MEM-SAFE-025a].
        unsafe Memory.Address(backing.unsafeBaseAddress)
    }
}

// MARK: - Pointer Primitive

extension Memory.Allocator.Pool {
    /// Returns the pointer to the slot at the given index (no bounds check).
    @inlinable
    internal func _pointer(at index: Index<Slot>) -> UnsafeMutableRawPointer {
        unsafe _baseAddress.mutablePointer.advanced(
            by: Index<Slot>.Offset(fromZero: index) * _slotStride
        )
    }
}

// MARK: - Free List Sentinel

extension Memory.Allocator.Pool {
    /// The end-of-list sentinel: one-past-last valid slot index.
    ///
    /// Analogous to `endIndex` in Swift collections. A free list link
    /// equal to the sentinel means "no next free slot." Derived from
    /// capacity — not an arbitrary magic constant.
    @inlinable
    internal var _sentinel: Index<Slot> { _capacity.map(Ordinal.init) }
}

// MARK: - Properties

extension Memory.Allocator.Pool {
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

extension Memory.Allocator.Pool {
    /// Allocates a slot and returns its index.
    ///
    /// Prefers reusing freed slots (free list). Falls back to virgin cursor.
    /// The returned slot contains uninitialized memory — the caller must
    /// initialize it before use.
    ///
    /// - Returns: Index of the allocated slot.
    /// - Throws: `.exhausted` if no free or virgin slots remain.
    /// - Complexity: O(1)
    @inlinable
    public mutating func allocateSlot() throws(Memory.Allocator.Pool.Error) -> Index<Slot> {
        // Try free list first (reused slots)
        if _freeHead != _sentinel {
            let slot = _freeHead
            _freeHead = unsafe _pointer(at: slot).load(as: Index<Slot>.self)
            _allocationBits[slot.retag(Bit.self)] = true
            _allocated += .one
            return slot
        }

        // Try virgin cursor
        guard _nextUnused < _sentinel else {
            throw .exhausted(capacity: _capacity)
        }

        let slot = _nextUnused
        // Safe: we just verified `_nextUnused < _sentinel`, so +1 cannot overflow.
        _nextUnused = try! _nextUnused + .one
        _allocationBits[slot.retag(Bit.self)] = true
        _allocated += .one
        return slot
    }

    /// Returns a slot to the free list by index.
    ///
    /// The caller MUST deinitialize any typed content stored in the slot
    /// before calling this method.
    ///
    /// - Parameter slot: A slot index previously returned by `allocateSlot()`.
    /// - Throws: `.doubleFree` if the slot is already free.
    /// - Complexity: O(1)
    @inlinable
    public mutating func deallocate(at slot: Index<Slot>) throws(Memory.Allocator.Pool.Error) {
        let bitIndex = slot.retag(Bit.self)
        guard _allocationBits[bitIndex] else {
            throw .doubleFree
        }

        // Clear allocation bit.
        _allocationBits[bitIndex] = false

        // Push current head into this slot, make slot new head (LIFO).
        unsafe _pointer(at: slot).storeBytes(of: _freeHead, as: Index<Slot>.self)
        _freeHead = slot
        _allocated = _allocated.subtract.saturating(.one)
    }
}

// MARK: - Pointer-Based Operations

extension Memory.Allocator.Pool {
    /// Allocates a slot and returns a pointer to its memory.
    ///
    /// The returned pointer addresses `slotStride` bytes of uninitialized memory.
    /// The caller is responsible for initializing the memory before use and
    /// deinitializing it before calling `deallocate`.
    ///
    /// - Returns: Mutable raw pointer to the allocated slot.
    /// - Throws: `.exhausted` if no free slots remain.
    /// - Complexity: O(1)
    @inlinable
    public mutating func allocate() throws(Memory.Allocator.Pool.Error) -> UnsafeMutableRawPointer {
        try unsafe _pointer(at: allocateSlot())
    }

    /// Returns a slot to the free list.
    ///
    /// The caller MUST deinitialize any typed content stored in the slot
    /// before calling this method.
    ///
    /// - Parameter pointer: A pointer previously returned by `allocate()`.
    /// - Throws: `.foreignPointer` if the pointer does not belong to this pool.
    ///           `.doubleFree` if the slot is already free.
    /// - Complexity: O(1)
    @inlinable
    public mutating func deallocate(
        _ pointer: UnsafeMutableRawPointer
    ) throws(Memory.Allocator.Pool.Error) {
        guard let slot = unsafe index(for: pointer) else {
            throw .foreignPointer
        }
        try deallocate(at: slot)
    }

    /// Returns all slots to the free list.
    ///
    /// - Warning: All previously returned pointers become invalid.
    ///   The caller MUST deinitialize any typed content in all allocated
    ///   slots before calling this method.
    /// - Complexity: O(n/64) where n is capacity (clear bits only).
    @inlinable
    public mutating func reset() {
        _freeHead = _sentinel
        _nextUnused = .zero
        _allocated = .zero
        _allocationBits.clear.all()
    }
}

// MARK: - Slot Address Queries

extension Memory.Allocator.Pool {
    /// Returns the pointer to the slot at the given index.
    ///
    /// - Parameter index: A slot index. Must be < capacity.
    /// - Returns: Pointer to the slot's memory.
    /// - Precondition: `index < capacity`
    @inlinable
    public func pointer(at index: Index<Slot>) -> UnsafeMutableRawPointer {
        precondition(index < _capacity, "Slot index out of bounds")
        return unsafe _pointer(at: index)
    }

    /// Returns the slot index for a pointer previously returned by `allocate()`.
    ///
    /// - Parameter pointer: A pointer belonging to this pool.
    /// - Returns: The slot index, or `nil` if the pointer is foreign.
    @inlinable
    public func index(for pointer: UnsafeMutableRawPointer) -> Index<Slot>? {
        let rawOffset = unsafe pointer - _baseAddress.mutablePointer
        guard rawOffset >= 0 else { return nil }

        let byteCount = Memory.Address.Count(UInt(rawOffset))
        guard byteCount < _capacity * _slotStride else { return nil }

        let (slotCount, remainder) = _slotStride.quotientAndRemainder(dividing: byteCount)
        guard remainder == .zero else { return nil }

        return slotCount.map(Ordinal.init)
    }

}

// MARK: - Sendable

/// Sendable conformance for `Memory.Allocator.Pool`.
///
/// ## Safety Invariant
///
/// `Memory.Allocator.Pool` is `struct ~Copyable` owning a `Memory.Contiguous<Byte>` region (which
/// owns the out-of-line storage and frees it on `deinit`) and a `Bit.Vector` allocation bitmap. The
/// encapsulation invariant is asserted by the adjacent `// SAFETY:` comment per [MEM-SAFE-025a]; the
/// `@safe` attribute is forbidden in `Sources/` per [MEM-SAFE-025b]. Unique ownership guarantees at
/// most one thread mutates pool state; cross-thread transfer via move relinquishes the sender's
/// access.
///
/// ## Non-Goals
///
/// - Not a concurrent allocator — external synchronization required.
/// - Pointers returned by `allocate()` are not Sendable independently.
extension Memory.Allocator.Pool: @unsafe @unchecked Sendable {}
