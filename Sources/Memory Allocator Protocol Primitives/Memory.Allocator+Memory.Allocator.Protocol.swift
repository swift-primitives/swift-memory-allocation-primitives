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

// MARK: - Allocating (passthrough — the whole resource is one allocation)

/// The passthrough witness conformance lives in the Protocol target, not the namespace root: it
/// references `__MemoryAllocatorProtocol` (the hoisted `Memory.Allocator.`Protocol``), which the
/// root cannot depend on without a package cycle (`Protocol → root`, per [MOD-017]). Self-conformance
/// uses the **hoisted** name — the canonical `Memory.Allocator.`Protocol`` self-reference is the
/// [API-IMPL-009] circular reference.
///
/// A bare `Memory.Allocator<Resource>` is the passthrough allocator: it adopts the whole resource as
/// one allocation. The byte extent is read through the public `Memory.Region` seam (`capacity` / `base`),
/// not the module-internal `resource` storage, so the `@inlinable` seam stays inlinable across the
/// package boundary ([MOD-036]).
extension Memory.Allocator: __MemoryAllocatorProtocol where Resource: ~Copyable {
    /// The passthrough's failure channel — `Never`.
    ///
    /// It adopts a fixed region and traps on an over-capacity request, so no recoverable error can
    /// occur.
    public typealias Error = Never

    /// Hands out the whole resource region as a single allocation, returning its base (the seam).
    ///
    /// - Precondition: `count` does not exceed the adopted region's capacity (traps otherwise — the
    ///   passthrough's `Never` failure channel).
    @inlinable
    public mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) throws(Never) -> Memory.Address {
        precondition(
            count <= capacity,
            "passthrough allocator: requested byte count exceeds the adopted region's capacity"
        )
        return base
    }

    /// Returns a previously-vended allocation — a **no-op** for the passthrough (the seam): the whole
    /// region is reclaimed by the resource's own `deinit`.
    @inlinable
    public mutating func deallocate(
        _ address: Memory.Address,
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) {
        // Passthrough: the whole resource is one allocation; no per-allocation free.
    }
}
