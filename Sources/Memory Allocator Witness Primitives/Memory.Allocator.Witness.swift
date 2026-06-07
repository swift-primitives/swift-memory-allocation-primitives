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
    /// The type-erased allocator witness.
    ///
    /// `Memory.Allocator.Witness<Failure>` is a closure-backed implementation of
    /// `Memory.Allocator.\`Protocol\``, suitable for wrapping any conforming allocator behind a
    /// single nominal type or for constructing an allocator directly from `allocate`/`deallocate`
    /// closures.
    ///
    /// ## Witness naming — `Namespace.Witness`
    ///
    /// Per `operation-domain-naming-and-organization.md` §5, the canonical type-erased witness of
    /// an operation domain is nested as `Namespace.Witness` — here `Memory.Allocator.Witness`,
    /// mirroring `Iterator.Witness`. The witness is generic over the `Failure` error type, which
    /// supplies the protocol's associated `Error`.
    ///
    /// No result-noun alias is added (`operation-domain-naming-and-organization.md` §5.2): the
    /// deverbal noun of *allocate* is *allocation*, which is already taken by the allocated-region
    /// result type `Memory.Allocation`, so the witness has no alias and consumers use
    /// `Memory.Allocator.Witness`.
    public struct Witness<Failure: Swift.Error>: ~Copyable {
        @usableFromInline
        internal var _allocate: (
            _ count: Memory.Address.Count,
            _ alignment: Memory.Alignment
        ) throws(Failure) -> Memory.Address

        @usableFromInline
        internal var _deallocate: (
            _ address: Memory.Address,
            _ count: Memory.Address.Count,
            _ alignment: Memory.Alignment
        ) -> Void

        /// Construct an allocator from `allocate`/`deallocate`-shaped closures.
        ///
        /// - Parameters:
        ///   - allocate: Vends an aligned address for `count` bytes, or throws `Failure`.
        ///   - deallocate: Returns a previously-vended address; a no-op for bump allocators.
        @inlinable
        public init(
            allocate: @escaping (
                _ count: Memory.Address.Count,
                _ alignment: Memory.Alignment
            ) throws(Failure) -> Memory.Address,
            deallocate: @escaping (
                _ address: Memory.Address,
                _ count: Memory.Address.Count,
                _ alignment: Memory.Alignment
            ) -> Void
        ) {
            self._allocate = allocate
            self._deallocate = deallocate
        }
    }
}

// MARK: - Memory.Allocator.Protocol

extension Memory.Allocator.Witness: Memory.Allocator.`Protocol` {
    /// Allocates memory for the specified count and alignment.
    ///
    /// - Returns: A mutable address to the allocated memory.
    /// - Throws: `Failure` if the backing closure fails.
    @inlinable
    public mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) throws(Failure) -> Memory.Address {
        try _allocate(count, alignment)
    }

    /// Deallocates previously allocated memory.
    @inlinable
    public mutating func deallocate(
        _ address: Memory.Address,
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) {
        _deallocate(address, count, alignment)
    }
}
