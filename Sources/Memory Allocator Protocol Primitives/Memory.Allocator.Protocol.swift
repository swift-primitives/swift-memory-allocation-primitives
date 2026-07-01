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
public import Memory_Allocator_Primitive
public import Memory_Primitive

/// The allocate/deallocate capability seam — a carve/recycle capability over raw bytes (typed throws).
///
/// This is the active capability protocol of the allocation operation domain, homed on the **agent
/// noun** `Memory.Allocator` as the canonical triple: `Memory.Allocator` /
/// `Memory.Allocator.`Protocol`` / `Memory.Allocating` (the `Iterator.Protocol`/`Iterating`
/// precedent, [API-IMPL-023] / [PKG-NAME-002]).
///
/// `Memory.Allocator<Resource>` is itself a generic struct, so it cannot nest a protocol on 6.3.2.
/// Per [API-IMPL-009] the protocol is hoisted to module scope as `__MemoryAllocatorProtocol` and
/// re-exposed via the param-free `typealias `Protocol`` below; `Memory.Allocator.`Protocol``
/// resolves UNBOUND because the root `Memory` is non-generic (`[Verified: 2026-06-22]`, swiftc 6.3.2).
/// Declaring-module conformers (`Memory.Allocator`'s own passthrough) and sibling conformers
/// (`Memory.Allocator.Pool`, `Memory.Allocator.Arena`) MUST conform via this hoisted name, never via
/// the `.`Protocol`` alias — that self-reference is the [API-IMPL-009] cycle.
///
/// It is a **deletable convenience capability seam** ([API-IMPL-023]) — used for generic algorithms
/// over any allocator. Canonical allocator-product spellings stay concrete
/// (`Memory.Allocator<Memory.Heap>.Pool`), never the existential `any`-form of `Memory.Allocator.`Protocol``.
public protocol __MemoryAllocatorProtocol: ~Copyable {
    /// The typed error this allocator throws.
    associatedtype Error: Swift.Error

    /// Allocates `count` bytes at `alignment`, returning the address (the seam).
    mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) throws(Self.Error) -> Memory.Address

    /// Returns the allocation at `address` (the seam).
    mutating func deallocate(
        _ address: Memory.Address,
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    )
}

extension Memory.Allocator where Resource: ~Copyable {
    /// The canonical capability protocol of the allocator domain.
    ///
    /// Re-exposed from the hoisted `__MemoryAllocatorProtocol` per [API-IMPL-009]. Consumers spell it
    /// `Memory.Allocator.`Protocol`` or via the gerund alias `Memory.Allocating`.
    public typealias `Protocol` = __MemoryAllocatorProtocol
}
