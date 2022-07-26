const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;

pub fn Deque(comptime T: type) type {
    return struct {
        tail: usize,
        head: usize,
        buf: Buffer,

        const Self = @This();
        const Buffer = std.ArrayList(T);

        pub fn init(allocator: Allocator) Self {
            return .{
                .tail = 0,
                .head = 0,
                .buf = Buffer.init(allocator),
            };
        }

        pub fn initCapacity(allocator: Allocator, num: usize) !Self {
            const buf = try Buffer.initCapacity(allocator, num);
            return .{
                .tail = 0,
                .head = 0,
                .buf = buf,
            };
        }

        pub fn deinit(self: Self) void {
            self.buf.deinit();
        }

        pub fn pushBack(self: *Self, item: T) !void {
            // TODO
        }

        pub fn pushFront(self: *Self, item: T) !void {
            // TODO
        }

        pub fn popBack(self: *Self) ?T {
            // TODO
            return null;
        }

        pub fn popFront(self: *Self) ?T {
            // TODO
            return null;
        }

        /// Returns `true` if the buffer is at full capacity.
        fn isFull(self: Self) bool {
            return self.buf.capacity - self.buf.items.len == 1;
        }

        fn grow(self: *Self) !void {
            assert(self.isFull());
            const old_cap = self.buf.capacity;

            // Reserve additional space to accomodate more items
            try self.buf.ensureUnusedCapacity(old_cap);
            // Update `tail` and `head` pointers accordingly
            self.handleCapacityIncrease(old_cap);

            assert(self.buf.capacity >= old_cap * 2);
            assert(!self.isFull());
        }

        /// Updates `tail` and `head` values to handle the fact that we just reallocated the internal buffer.
        fn handleCapacityIncrease(self: *Self, old_capacity: usize) void {
            const new_capacity = self.buf.capacity;

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
                const new_tail = new_capacity - (old_capacity - seif.tail);
                self.copyNonOverlapping(new_tail, self.tail, old_capacity - self.tail);
                self.tail = new_tail;
                assert(self.head < self.tail);
            }
            assert(self.head < self.buf.capacity);
            assert(self.tail < self.buf.capacity);
        }

        fn copyNonOverlapping(self: *Self, dest: usize, src: usize, len: usize) void {
            assert(dest + len <= self.buf.capacity);
            assert(src + len <= self.buf.capacity);
            mem.copy(T, self.buf.items[dest .. dest + len], self.buf.items[src .. src + len]);
        }
    };
}
