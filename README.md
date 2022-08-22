# zig-deque

Double-ended queue implementation in Zig, ported from [the Rust's standard library](https://doc.rust-lang.org/std/collections/struct.VecDeque.html).

## Usage

```zig
const std = @import("std");

var deque = try Deque(usize).init(std.heap.page_allocator);
defer deque.deinit();

// You can efficiently push items to both ends
try deque.pushBack(1);
try deque.pushBack(2);
try deque.pushFront(0);

// Possible to random-access via `get` method
std.debug.assert(deque.get(0).?.* == @as(usize, 0));
std.debug.assert(deque.get(1).?.* == @as(usize, 1));
std.debug.assert(deque.get(2).?.* == @as(usize, 2));
std.debug.assert(deque.get(3) == null);

// An iterator is provided
var it = deque.iterator();
var sum: usize = 0;
while (it.next()) |val| {
    sum += val.*;
}
std.debug.assert(sum == 3);

// Of course, you can pop items from both ends
std.debug.assert(deque.popFront().? == @as(usize, 0));
std.debug.assert(deque.popBack().? == @as(usize, 2));
```

## Version

Tested under both v0.9.1 and v0.10.0-dev.3659+e5e6eb983
