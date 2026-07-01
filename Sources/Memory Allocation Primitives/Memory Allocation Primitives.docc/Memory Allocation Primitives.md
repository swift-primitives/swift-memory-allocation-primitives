# ``Memory_Allocation_Primitives``

@Metadata {
    @DisplayName("Memory Allocation Primitives")
    @TitleHeading("Swift Primitives")
}

Allocators that carve a raw memory region — `Memory.Heap` or `Memory.Inline<n>` — into slots. A bare `Memory.Allocator<Resource>` is itself the passthrough allocator (it adopts the whole resource as one allocation); a bump `Arena` and an O(1) fixed-size `Pool` are sibling strategies, all expressed through the `Memory.Allocating` capability seam — homed on the agent noun `Memory.Allocator` — with typed-throws errors.

## Topics

### The allocation seam

- ``Memory/Allocation``

### Allocators

- ``Memory/Allocator``
```
