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
    /// The system allocator, as a type-erased witness.
    ///
    /// `Memory.Allocator.system` vends aligned addresses straight from the platform allocator
    /// (`UnsafeMutableRawPointer.allocate(count:alignment:)`) and traps on exhaustion, so its
    /// failure channel is `Never`. It is expressed as the closure-backed witness
    /// `Memory.Allocator.Witness<Never>` — the system-allocator body that previously lived on the
    /// `Memory.Allocator` *struct* in `swift-memory-primitives` — mirroring how `Iterator.repeating`
    /// is expressed directly as `Iterator.Witness` rather than a dedicated concrete type.
    ///
    /// The system allocator needs no `count`/`alignment` for deallocation.
    @inlinable
    public static var system: Memory.Allocator.Witness<Never> {
        Memory.Allocator.Witness<Never>(
            allocate: { (count, alignment) throws(Never) -> Memory.Address in
                unsafe Memory.Address(
                    UnsafeMutableRawPointer.allocate(count: count, alignment: alignment)
                )
            },
            deallocate: { (address, _, _) in
                // System allocator doesn't need count/alignment for deallocation.
                unsafe UnsafeMutableRawPointer(address).deallocate()
            }
        )
    }
}
