const std = @import("std");
const mem = std.mem;
const math = std.math;
const Allocator = mem.Allocator;
const assert = std.debug.assert;

pub fn Deque(comptime T: type) type {
    return struct {
        tail: usize,
        head: usize,
        /// Users should **NOT** use this field directly.
        /// In order to access an item with an index, use `get` method.
        /// If you want to iterate over the items, call `iterate` method to get the iterator.
        buf: []T,
        allocator: Allocator,

        const Self = @This();
        const INITIAL_CAPACITY = 7; // 2^3 - 1
        const MINIMUM_CAPACITY = 1; // 2 - 1

        /// Creates an empty deque.
        pub fn init(allocator: Allocator) !Self {
            return initCapacity(allocator, INITIAL_CAPACITY);
        }

        /// Creates an empty deque with space for at least `capacity` elements.
        pub fn initCapacity(allocator: Allocator, capacity: usize) !Self {
            const effective_cap = try math.ceilPowerOfTwo(math.max(capacity + 1, MINIMUM_CAPACITY + 1));
            const buf = try allocator.alloc(T, effective_cap);
            return .{
                .tail = 0,
                .head = 0,
                .buf = buf,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.buf);
        }

        pub fn cap(self: Self) usize {
            return self.buf.len;
        }

        pub fn len(self: Self) usize {
            return count(self.tail, self.head, self.cap());
        }

        pub fn get(self: Self, index: usize) ?T {
            if (index >= self.len()) return null;

            const idx = self.wrapAdd(self.tail, index);
            return self.buf[idx];
        }

        // pub fn pushBack(self: *Self, item: T) !void {
        //     if (self.isFull()) {
        //         try self.grow();
        //     }

        //     const head = self.head;
        //     self.head = self.wrapAdd(self.head, 1);
        //     self.bufWrite(head, item);
        // }

        // pub fn pushFront(self: *Self, item: T) !void {
        //     // TODO
        // }

        // pub fn popBack(self: *Self) ?T {
        //     // TODO
        //     return null;
        // }

        // pub fn popFront(self: *Self) ?T {
        //     // TODO
        //     return null;
        // }

        /// Returns `true` if the buffer is at full capacity.
        fn isFull(self: Self) bool {
            return self.cap() - self.len() == 1;
        }

        fn grow(self: *Self) !void {
            assert(self.isFull());
            const old_cap = self.cap();

            // Reserve additional space to accomodate more items
            try self.buf.ensureUnusedCapacity(old_cap);
            // Update `tail` and `head` pointers accordingly
            self.handleCapacityIncrease(old_cap);

            assert(self.cap() >= old_cap * 2);
            assert(!self.isFull());
        }

        /// Updates `tail` and `head` values to handle the fact that we just reallocated the internal buffer.
        fn handleCapacityIncrease(self: *Self, old_capacity: usize) void {
            const new_capacity = self.cap();

            // Move the shortest contiguous section of the ring buffer.
            // There are three cases to consider:
            //
            // (A) No need to update
            //          T             H
            // before: [o o o o o o o . ]
            //
            // after : [o o o o o o o . . . . . . . . . ]
            //          T             H
            //
            //
            // (B) [..H] needs to be moved
            //              H T
            // before: [o o . o o o o o ]
            //          ---
            //           |_______________.
            //                           |
            //                           v
            //                          ---
            // after : [. . . o o o o o o o . . . . . . ]
            //                T             H
            //
            //
            // (C) [T..old_capacity] needs to be moved
            //                    H T
            // before: [o o o o o . o o ]
            //                      ---
            //                       |_______________.
            //                                       |
            //                                       v
            //                                      ---
            // after : [o o o o o . . . . . . . . . o o ]
            //                    H                 T

            if (self.tail <= self.head) {
                // (A), Nop
            } else if (self.head < old_capacity - self.tail) {
                // (B)
                self.copyNonOverlapping(old_capacity, 0, self.head);
                self.head += old_capacity;
                assert(self.head > self.tail);
            } else {
                // (C)
                const new_tail = new_capacity - (old_capacity - self.tail);
                self.copyNonOverlapping(new_tail, self.tail, old_capacity - self.tail);
                self.tail = new_tail;
                assert(self.head < self.tail);
            }
            assert(self.head < self.cap());
            assert(self.tail < self.cap());
        }

        fn copyNonOverlapping(self: *Self, dest: usize, src: usize, length: usize) void {
            assert(dest + length <= self.cap());
            assert(src + length <= self.cap());
            mem.copy(T, self.buf.items[dest .. dest + length], self.buf.items[src .. src + length]);
        }

        fn wrapAdd(self: Self, idx: usize, addend: usize) usize {
            return wrapIndex(idx +% addend, self.cap());
        }

        fn wrapSub(self: Self, idx: usize, subtrahend: usize) usize {
            return wrapIndex(idx -% subtrahend, self.cap());
        }
    };
}

fn count(tail: usize, head: usize, size: usize) usize {
    assert(math.isPowerOfTwo(size));
    return (head -% tail) & (size - 1);
}

fn wrapIndex(index: usize, size: usize) usize {
    assert(math.isPowerOfTwo(size));
    return index & (size - 1);
}
