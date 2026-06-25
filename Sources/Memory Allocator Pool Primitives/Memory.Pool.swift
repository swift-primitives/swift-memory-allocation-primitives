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

public import Index_Primitives
public import Memory_Address_Primitives
public import Memory_Primitive

extension Memory {
    /// The pool ALGEBRA's home — the non-generic namespace for the slot-universe
    /// vocabulary (the canonical triple: `Memory.Pool` / `Memory.Pool.\`Protocol\`` /
    /// `Memory.Pooling`, the `Iterator.Protocol`/`Iterating` precedent).
    ///
    /// `Memory.Allocator<Resource>.Pool` is the canonical MODEL; this namespace is the
    /// algebra it realizes, and the REAL home of the discipline's Resource-independent
    /// vocabulary. The vocabulary cannot nest in the generic model: a typed-throws
    /// `Error` nested in `Memory.Allocator<Resource>` is phantom-generic over `Resource`
    /// (it never uses it) and, thrown across the `Memory.Allocating` witness, trips the
    /// §A13 release-optimizer assertion (`FunctionSignatureOpts` fails
    /// `(!type.hasTypeParameter())`, `SILArgument.cpp:40`; swiftlang/swift#89617 —
    /// affected 6.2 → 6.5-dev). `Memory.Allocator.Pool.Slot` / `.Error` alias into here.
    public enum Pool {
        /// Phantom tag for slot-level indexing within a pool (types `Index<Slot>`) —
        /// the algebra's primitive.
        public enum Slot {}

        /// Errors that can occur during pool operations.
        ///
        /// Properties of the pool's discipline, not of any particular backing.
        /// Backing-independence is what lets the seam throw CONCRETELY.
        public enum Error: Swift.Error, Equatable, Sendable {
            /// No free slots remain.
            case exhausted(capacity: Index<Slot>.Count)
            /// The slot size is too small to hold the in-band free list pointer.
            case slotSizeTooSmall(requested: Memory.Address.Count, minimum: Memory.Address.Count)
            /// The requested capacity is invalid (must be > 0).
            case invalidCapacity
            /// The pointer does not belong to this pool.
            case foreignPointer
            /// The slot has already been deallocated (double free).
            case doubleFree
        }
    }
}
