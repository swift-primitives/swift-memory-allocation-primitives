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

extension Memory {
    /// The active-capability gerund alias for `Memory.Allocator.\`Protocol\``.
    ///
    /// Per `[PKG-NAME-002]` / `operation-domain-naming-and-organization.md` §4.1, the active
    /// capability protocol is declared as the nested `Memory.Allocator.\`Protocol\`` and exported
    /// under its gerund reading so conformance and constraint sites read as English:
    ///
    /// ```swift
    /// func reserve<A: Memory.Allocating>(from allocator: inout A) throws(A.Error) { … }
    /// ```
    ///
    /// The alias is **scoped under `Memory`** (it is `Memory.Allocating`, not a top-level
    /// `Allocating`) because "allocating" without the `Memory` subject would be ambiguous in the
    /// wider ecosystem. `Memory.Allocator.\`Protocol\`` remains the canonical declaration the alias
    /// targets, used where `Memory.Allocating` would itself be ambiguous.
    public typealias Allocating = Memory.Allocator.`Protocol`
}
