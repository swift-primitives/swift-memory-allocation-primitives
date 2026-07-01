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
public import Memory_Allocation_Primitive
public import Memory_Primitive

extension Memory.Allocator.Arena where Resource: ~Copyable {
    /// The arena's typed errors — raised when a bump request cannot be satisfied.
    public enum Error: Swift.Error, Equatable, Sendable {
        /// Insufficient space in arena.
        case insufficientCapacity(requested: Memory.Address.Count, available: Memory.Address.Count)
    }
}
