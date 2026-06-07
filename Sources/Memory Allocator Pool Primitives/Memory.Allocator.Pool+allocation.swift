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

// MARK: - Allocation Property Accessor

extension Memory.Allocator.Pool {
    /// Read-only allocation-level properties.
    ///
    /// Provides namespaced access to allocation state:
    /// - `pool.allocation.indices` — indices of all currently allocated slots
    @inlinable
    public var allocation: Property<Memory.Allocation, Self>.Borrow {
        _read {
            yield Property<Memory.Allocation, Self>.Borrow(self)
        }
    }
}

// MARK: - Allocation Property.Borrow Extensions

// `Property.Borrow` is parameterized by `Tag` and `Base` only, so the member extension binds the
// concrete pool as its `Base`.
extension Property.Borrow where Tag == Memory.Allocation, Base == Memory.Allocator.Pool {
    /// Indices of all currently allocated slots.
    @inlinable
    public var indices: Bit.Vector.Ones.View {
        base.value._allocationBits.ones
    }
}
