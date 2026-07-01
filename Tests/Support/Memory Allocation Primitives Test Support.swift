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

public import Memory_Primitive
public import Memory_Allocator_Pool_Primitives
import Index_Primitives

extension Memory.Pool {
    /// THE POOL LAWS (L1–L5, seat-ruled 2026-06-10) — the law harness every
    /// `Memory.Pooling` conformer runs from its consuming suite (the [DS-024] sibling
    /// for the pool capability seam).
    ///
    /// The harness drives the conformer EXCLUSIVELY through the protocol's witnesses
    /// (the generic dispatch is itself under test — the §A15-clean protocol-bound shape).
    public enum Laws {
        /// Runs the laws over a fresh pool built by `makePool` and returns
        /// human-readable descriptions of every violation (empty = lawful).
        ///
        /// - Parameters:
        ///   - makePool: builds a FRESH, EMPTY pool of `expectedCapacity` slots, each at
        ///     least `MemoryLayout<Int>.stride` bytes (the harness writes `Int` patterns).
        ///   - expectedCapacity: the constructed slot capacity (≥ 2).
        public static func violations<P: Memory.Pooling & ~Copyable>(
            makePool: () -> P,
            expectedCapacity: Int
        ) -> [String] {
            var found: [String] = []
            var pool = makePool()

            // Observation: capacity is as constructed.
            if Int(bitPattern: pool.capacity) != expectedCapacity {
                found.append("capacity: constructed \(expectedCapacity) but observes \(pool.capacity)")
            }

            // L4 (totality, allocate side) + L1 (identity): claim the whole universe —
            // every allocation names a distinct slot; the (capacity+1)-th throws.
            var slots: [Index<Memory.Pool.Slot>] = []
            while true {
                do {
                    let slot = try pool.allocateSlot()
                    if slots.contains(slot) {
                        found.append("L1: allocateSlot handed out live slot \(slot) twice")
                    }
                    slots.append(slot)
                } catch {
                    if slots.count != expectedCapacity {
                        found.append("L4: exhausted after \(slots.count) of \(expectedCapacity) slots")
                    }
                    break
                }
                if slots.count > expectedCapacity {
                    found.append("L4: allocated past the constructed capacity")
                    break
                }
            }

            // L2 (geometry): distinct slots occupy disjoint regions (≥ Int.stride apart —
            // the harness's documented minimum slot size).
            let addresses = slots.map { slot in
                unsafe Int(bitPattern: pool.pointer(at: slot))
            }
            for i in addresses.indices {
                for j in addresses.indices where i < j {
                    let distance = addresses[i] > addresses[j]
                        ? addresses[i] - addresses[j]
                        : addresses[j] - addresses[i]
                    if distance < MemoryLayout<Int>.stride {
                        found.append("L2: slots \(slots[i]) and \(slots[j]) overlap (distance \(distance))")
                    }
                }
            }

            // L5 (non-interference) setup: a distinct pattern per slot.
            for (ordinal, slot) in slots.enumerated() {
                unsafe pool.pointer(at: slot).storeBytes(of: ordinal &+ 1, as: Int.self)
            }

            // L1+L3 (borrow-scoped address stability): churn one slot (deallocate +
            // re-allocate — the pool is exhausted, so the free list MUST hand the same
            // location back); other slots' addresses are unmoved and contents intact.
            if let churn = slots.first {
                do {
                    try pool.deallocate(at: churn)
                    let reused = try pool.allocateSlot()
                    if reused != churn {
                        found.append("L1: exhausted pool reused \(reused) for freed slot \(churn)")
                    }
                    unsafe pool.pointer(at: reused).storeBytes(of: 1, as: Int.self)
                } catch {
                    found.append("L4: churn on a proven-live slot threw \(error)")
                }
            }
            for (ordinal, slot) in slots.enumerated() {
                let address = unsafe Int(bitPattern: pool.pointer(at: slot))
                if address != addresses[ordinal] {
                    found.append("L3: slot \(slot) moved from \(addresses[ordinal]) to \(address) across unrelated ops")
                }
                let value = unsafe pool.pointer(at: slot).load(as: Int.self)
                if value != ordinal &+ 1 {
                    found.append("L5: slot \(slot) held \(value), expected \(ordinal &+ 1)")
                }
            }

            // L4 (totality, deallocate side): returning every live slot cannot fail;
            // a second deallocate of the same slot throws (double-free detection).
            for slot in slots {
                do {
                    try pool.deallocate(at: slot)
                } catch {
                    found.append("L4: deallocate of live slot \(slot) threw \(error)")
                }
            }
            if let first = slots.first {
                do {
                    try pool.deallocate(at: first)
                    found.append("L4: double-free of \(first) did not throw")
                } catch {
                    // lawful: the discipline detects the double free.
                }
            }

            return found
        }
    }
}
