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

extension Memory.Allocator.Pool {
    /// Phantom type for slot-level indexing within a pool.
    ///
    /// A slot index identifies a position in the slot grid; the tag carries no
    /// storage and exists only to type `Index<Slot>`.
    public enum Slot {}
}
