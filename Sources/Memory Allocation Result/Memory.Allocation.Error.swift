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

extension Memory.Allocation {
    /// Errors from memory allocation operations.
    public enum Error: Swift.Error, Sendable, Equatable, Hashable {
        /// Out of memory (`ENOMEM` / `ERROR_NOT_ENOUGH_MEMORY`).
        case exhausted
    }
}

// MARK: - CustomStringConvertible

extension Memory.Allocation.Error: CustomStringConvertible {
    /// A textual representation of the error.
    public var description: Swift.String {
        switch self {
        case .exhausted:
            return "out of memory"
        }
    }
}

// MARK: - Platform Bindings
//
// Per [PLAT-ARCH-008c], the platform-specific `init?(code:)` mapping lives in L2:
// - POSIX: `swift-iso-9945` (`ISO 9945.Memory.Allocation.Error+code.swift`)
// - Windows: `swift-windows-standard` (`Windows.Memory.Allocation.Error+code.swift`)
