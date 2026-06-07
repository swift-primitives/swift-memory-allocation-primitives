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

// MARK: - Slot Property Accessor

extension Memory.Allocator.Pool {
    /// Read-only slot-level properties.
    ///
    /// Provides namespaced access to per-slot geometry:
    /// - `pool.slot.stride` — scaling factor from slot domain to byte domain
    /// - `pool.slot.alignment` — alignment requirement for each slot
    @inlinable
    public var slot: Property<Slot, Self>.Borrow {
        _read {
            yield Property<Slot, Self>.Borrow(self)
        }
    }
}

// MARK: - Slot Property.Borrow Extensions

// `Property.Borrow` is parameterized by `Tag` and `Base` only, so the member extension binds the
// concrete pool as its `Base`.
extension Property.Borrow where Tag == Memory.Allocator.Pool.Slot, Base == Memory.Allocator.Pool {
    /// Scaling factor from slot domain to byte domain (stride-aligned).
    @inlinable
    public var stride: Affine.Discrete.Ratio<Memory.Allocator.Pool.Slot, Memory> {
        base.value._slotStride
    }

    /// Alignment requirement for each slot.
    @inlinable
    public var alignment: Memory.Alignment {
        base.value._slotAlignment
    }
}
