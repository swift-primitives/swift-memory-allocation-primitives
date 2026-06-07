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
    /// The allocator protocol — the operation-domain agent for allocation.
    ///
    /// Conforming types provide allocation and deallocation operations
    /// with customizable strategies (system, arena, pool, etc.).
    ///
    /// Per `operation-domain-naming-and-organization.md` §4.1 this is the active capability
    /// protocol, declared nested as `Memory.Allocator.\`Protocol\`` and exported under the gerund
    /// alias `Memory.Allocating` (scoped under `Memory`).
    ///
    /// ## Alignment
    ///
    /// Both `allocate` and `deallocate` take alignment parameters.
    /// Some allocators need alignment info for deallocation (e.g., Windows `_aligned_free`).
    /// Allocators that don't need it can ignore the parameter.
    public protocol `Protocol`: ~Copyable {
        /// Error type for allocation failures.
        associatedtype Error: Swift.Error

        /// Allocates memory for the specified count and alignment.
        ///
        /// - Parameters:
        ///   - count: Number of bytes to allocate.
        ///   - alignment: Required alignment (power of 2).
        /// - Returns: A mutable address to the allocated memory.
        /// - Throws: `Error` if allocation fails.
        mutating func allocate(
            count: Memory.Address.Count,
            alignment: Memory.Alignment
        ) throws(Self.Error) -> Memory.Address

        /// Deallocates previously allocated memory.
        ///
        /// - Parameters:
        ///   - address: The address to deallocate.
        ///   - count: The original allocation size.
        ///   - alignment: The original alignment (some allocators require this).
        mutating func deallocate(
            _ address: Memory.Address,
            count: Memory.Address.Count,
            alignment: Memory.Alignment
        )
    }
}
