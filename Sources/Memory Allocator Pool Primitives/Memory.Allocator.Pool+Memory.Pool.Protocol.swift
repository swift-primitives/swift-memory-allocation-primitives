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

import Memory_Allocator_Primitive
public import Memory_Primitive

/// The ONE generic conformance: the canonical model realizes the capability for every
/// `Resource`. The quantifier is REAL — only heap CONSTRUCTION pins
/// (`init(slotSize:slotAlignment:capacity:)`); every operation is already
/// Resource-generic, so the members witness as-is (zero relocation, additive-only).
extension Memory.Allocator.Pool: Memory.Pool.`Protocol` where Resource: ~Copyable {}
