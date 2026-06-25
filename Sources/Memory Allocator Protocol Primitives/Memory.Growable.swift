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
public import Memory_Primitive
public import Memory_Region_Primitives

extension Memory {
    /// The **fresh byte-construction** capability — a `Memory.Region` that can allocate itself sized
    /// to a byte count.
    ///
    /// This is the marker the growable disciplines gate on (`store-capability-elimination.md` §1): a
    /// generic constrained to `Memory.Growable` grows by allocating a fresh region and relocating the
    /// live elements, at zero witness through a concrete tower. It is deliberately **separate from**
    /// `Memory.Allocatable` (the adopt-role): adoption is universal — every region, fixed or growable,
    /// can be wrapped as a passthrough allocator — whereas fresh allocation is the capability only the
    /// growable regions carry.
    ///
    /// Conformed by `Memory.Heap` (heap allocation) and `Memory.Small` (the inline⊕heap leaf, where
    /// this initializer IS the spill decision). **Not** conformed by `Memory.Inline`: its capacity is
    /// the fixed value-generic `n`, so it cannot be constructed to an arbitrary byte count — a growable
    /// column over `Memory.Inline` is correctly unrepresentable (it fails to compile).
    public protocol Growable: Memory.Region, ~Copyable {
        /// Allocates a fresh region of at least `byteCount` bytes at `alignment`.
        init(byteCount: Memory.Address.Count, alignment: Memory.Alignment)
    }
}
