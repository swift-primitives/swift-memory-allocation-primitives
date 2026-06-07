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

extension Memory.Allocator.Arena {
    /// Errors that can occur during arena operations.
    ///
    /// The arena's only failure mode is the bump cursor overflowing capacity.
    public enum Error: Swift.Error, Equatable, Sendable {
        /// Insufficient space in arena.
        case insufficientCapacity(requested: Memory.Address.Count, available: Memory.Address.Count)
    }
}
