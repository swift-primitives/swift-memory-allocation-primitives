# Memory Allocation Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-memory-allocation-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-memory-allocation-primitives/actions/workflows/ci.yml)

`Memory.Allocator<Resource>` — allocators that carve a raw memory region into slots. The allocator is generic over its backing `Resource` (any `Memory.Region` — a `Memory.Heap` for heap-backed allocation, a `Memory.Inline<n>` for allocation with no heap at all) and comes in three strategies: a passthrough `System` allocator that adopts the whole region as one allocation, a bump `Arena` that hands out a moving cursor and frees everything on `reset()`, and a fixed-size `Pool` that allocates and frees individual slots in O(1).

Allocation and deallocation are expressed through one capability seam, `Memory.Allocation.Protocol` (the gerund alias `Memory.Allocating`), so a consumer can be written against "something that allocates" and specialized to a concrete strategy. Every operation reports failure through a typed `throws` — a full pool, an oversized request, or a double free surface as a precise error rather than a trap.

---

## Key Features

- **Three strategies, one seam** — `System` (passthrough), `Arena` (bump / linear), and `Pool` (fixed-size slots), all conforming `Memory.Allocating`.
- **Heap- or inline-backed** — the same `Pool` allocates a fresh `Memory.Heap` region, or carves slots within an existing `Memory.Inline<n>` for an allocator with no heap allocation.
- **O(1) pool** — slot allocation and free are constant-time, using an in-band free list (a freed slot stores the next free index in its own bytes) plus a virgin cursor, so no free list is pre-built at construction.
- **Typed slot identity** — the pool vends `Index<Slot>`, a phantom-typed slot handle, never an element index; element typing is added one tier up at Storage.
- **Typed throws** — `allocate` / `deallocate` throw a precise, exhaustive error, not `any Error`.

---

## Quick Start

```swift
import Memory_Allocation_Primitives

// A fixed-size slot pool over a freshly allocated heap region.
var pool = try Memory.Allocator<Memory.Heap>.Pool(
    slotSize: slotSize,
    slotAlignment: slotAlignment,
    capacity: capacity
)

let slot = try pool.allocateSlot()   // O(1) — a typed Index<Slot>
let address = pool.pointer(at: slot) // the slot's raw address
try pool.deallocate(at: slot)        // O(1) — returns the slot to the free list

// Or back the same pool with inline bytes — no heap allocation at all:
var inlinePool = try Memory.Allocator<Memory.Inline<4096>>.Pool(
    carving: Memory.Inline<4096>(),
    slotSize: slotSize,
    slotAlignment: slotAlignment
)
```

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Memory Allocation Primitives` | Umbrella — re-exports the seam, the allocator, and the arena + pool strategies | Most consumers |
| `Memory Allocation Primitive` | `Memory.Allocation.Protocol` / `Memory.Allocating` — the allocate / deallocate capability seam — and `Memory.Allocation.Error` | Writing code generic over "something that allocates" |
| `Memory Allocator Primitive` | `Memory.Allocator<Resource>` and `Memory.Allocator.System`, the passthrough allocator | Naming the allocator base or the system allocator directly |
| `Memory Allocator Arena Primitives` | `Memory.Allocator.Arena` — the bump / linear allocator | Linear allocation with bulk `reset()` |
| `Memory Allocator Pool Primitives` | `Memory.Allocator.Pool` — the fixed-size slot pool | Fixed-size slot pooling |

---

## Error Handling

The pool's `allocate` / `allocateSlot` / `deallocate` and its initializers throw a typed `Memory.Allocator<Resource>.Pool.Error`:

```swift
do {
    let slot = try pool.allocateSlot()
    // ...
    try pool.deallocate(at: slot)
} catch .exhausted(let capacity) {
    // every slot is in use (the pool holds `capacity` slots)
} catch .doubleFree {
    // the slot was already free
} catch .invalidCapacity, .slotSizeTooSmall {
    // construction-time geometry errors
}
```

The bump arena throws `.insufficientCapacity(requested:available:)` when a request exceeds the bytes left in the region.

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Pending (nightly-toolchain follow-up) |

---

## Related Packages

- [`swift-memory-heap-primitives`](https://github.com/swift-primitives/swift-memory-heap-primitives) — `Memory.Heap`, the heap-allocated region an allocator carves.
- [`swift-memory-inline-primitives`](https://github.com/swift-primitives/swift-memory-inline-primitives) — `Memory.Inline<n>`, the inline region for heap-free allocation.
- [`swift-memory-primitives`](https://github.com/swift-primitives/swift-memory-primitives) — `Memory.Region`, the backing seam an allocator's `Resource` conforms to.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
