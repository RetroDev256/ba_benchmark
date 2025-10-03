const std = @import("std");
const Value = std.json.Value;
const options = @import("options");

// zig build -Doptimize=[...] -Dnew=[false/true]
const BumpAllocator = switch (options.new) {
    true => @import("BumpAllocator"),
    false => std.heap.FixedBufferAllocator,
};

pub fn main() !void {
    var buffer: [1 << 20]u8 = undefined;
    defer std.mem.doNotOptimizeAway(buffer);
    var bump_allocator: BumpAllocator = .init(&buffer);
    defer std.mem.doNotOptimizeAway(bump_allocator);
    const gpa = bump_allocator.allocator();

    for (0..100_000) |_| {
        switch (options.new) {
            true => bump_allocator.restore(@intFromPtr(&buffer)),
            false => bump_allocator.reset(),
        }

        try std.heap.testAllocator(gpa);
        try std.heap.testAllocatorAligned(gpa);
        try std.heap.testAllocatorAlignedShrink(gpa);
        try std.heap.testAllocatorLargeAlignment(gpa);
    }

    for (0..100_000) |_| {
        switch (options.new) {
            true => bump_allocator.restore(@intFromPtr(&buffer)),
            false => bump_allocator.reset(),
        }

        const json = @embedFile("test.json");
        const parsed = try std.json.parseFromSlice(Value, gpa, json, .{});
        parsed.deinit();
    }

    for (0..100_000) |_| {
        switch (options.new) {
            true => bump_allocator.restore(@intFromPtr(&buffer)),
            false => bump_allocator.reset(),
        }

        var list: std.ArrayList(u32) = .empty;
        defer list.deinit(gpa);

        try list.append(gpa, 1);
        try list.append(gpa, 2);
        try list.append(gpa, 3);
        try list.appendSlice(gpa, &.{ 4, 5, 6, 7, 8, 9, 10 });

        try list.insert(gpa, 0, 111);
        try list.insert(gpa, list.items.len / 2, 222);
        try list.append(gpa, 333);

        _ = list.orderedRemove(0);
        _ = list.orderedRemove(list.items.len / 2);
        _ = list.pop();

        try list.ensureTotalCapacity(gpa, 1000);
        list.shrinkAndFree(gpa, list.items.len);
    }
}
