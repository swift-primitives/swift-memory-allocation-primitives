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
//
// In-package surface tests for the element-free protocols (`Memory.Allocatable` adopt-role +
// `Memory.Growable` fresh-construction). They exercise the generic seam over a test-local
// `Memory.Region` stub so the package stays leaf-free (the concrete `Memory.Heap` / `Memory.Inline`
// integration tests live in the leaf packages, post dependency-inversion).

import Memory_Allocation_Primitives
import Testing

@Suite(.serialized)
struct MemoryAllocatableSurfaceTests {

    /// A self-owning raw byte region — the minimal `Memory.Growable` (and so `Memory.Allocatable`)
    /// stub.
    ///
    /// Owns a malloc'd block and frees it on `deinit` (move-only ⇒ single free).
    ///
    /// ## Safety Invariant
    ///
    /// `@safe` absorber ([MEM-SAFE-020]): `pointer` is a self-owned malloc'd block, freed exactly
    /// once on `deinit` (the struct is `~Copyable`). `base`/`capacity` only expose its extent; no
    /// caller can observe the raw pointer.
    @safe
    struct Region: Memory.Growable, Memory.Allocatable, ~Copyable {
        let pointer: UnsafeMutableRawPointer
        let byteCount: Int

        init(byteCount: Memory.Address.Count, alignment: Memory.Alignment) {
            let count = Int(bitPattern: byteCount)
            self.byteCount = count
            unsafe self.pointer = UnsafeMutableRawPointer.allocate(
                byteCount: count,
                alignment: alignment.magnitude(as: Int.self)
            )
        }

        var base: Memory.Address { unsafe Memory.Address(pointer) }
        var capacity: Memory.Address.Count { Memory.Address.Count(UInt(byteCount)) }

        deinit { unsafe pointer.deallocate() }
    }

    @Test func growableConstructsToTheRequestedByteCount() {
        let region = Region(byteCount: Memory.Address.Count(UInt(256)), alignment: .`8`)
        #expect(region.capacity == Memory.Address.Count(UInt(256)))
    }

    @Test func adoptRoleVendsAPassthroughOverTheWholeRegion() {
        let region = Region(byteCount: Memory.Address.Count(UInt(128)), alignment: .`8`)
        let allocator = region.makeAllocator()
        // The passthrough forwards the Region seam (base + capacity) of the adopted region.
        #expect(allocator.capacity == Memory.Address.Count(UInt(128)))
        #expect(allocator.base == allocator.base)
    }
}
