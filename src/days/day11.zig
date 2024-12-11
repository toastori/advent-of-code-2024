const std = @import("std");

const stone_hashmap = std.AutoHashMap(usize, usize);

var stones = [2]stone_hashmap{ undefined, undefined };

fn hashmapPutOrAdd(map: *std.AutoHashMap(usize, usize), key: usize, value: usize) !void {
    const result = try map.getOrPut(key);
    result.value_ptr.* = switch (result.found_existing) {
        true => result.value_ptr.* + value,
        false => value,
    };
}

/// Return next stones' start index to use
fn blink(start_index: usize, iteration: usize) !usize {
    var index = start_index ^ 1;
    var apply_index = start_index;
    for (0..iteration) |_| {
        var map_iter = stones[index].iterator();
        while (map_iter.next()) |stone| {
            const key = stone.key_ptr.*;
            const value = stone.value_ptr.*;

            if (key == 0) {
                try hashmapPutOrAdd(&stones[apply_index], 1, value);
                continue;
            }

            const digits = 1 + std.math.log10_int(key);
            if (digits % 2 == 0) {
                const tens = std.math.pow(usize, 10, digits / 2);
                try hashmapPutOrAdd(&stones[apply_index], key / tens, value);
                try hashmapPutOrAdd(&stones[apply_index], key % tens, value);
            } else {
                try hashmapPutOrAdd(&stones[apply_index], key * 2024, value);
            }
        }
        stones[index].clearRetainingCapacity();
        index ^= 1;
        apply_index ^= 1;
    }
    return apply_index;
}

pub fn day11(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    inline for (&stones) |*hashmap| {
        hashmap.* = stone_hashmap.init(allocator);
    }

    var fin_buffer: [12]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, ' ')) |word| {
        const num = try std.fmt.parseInt(usize, word[0..if (word[word.len - 1] == '\n') word.len - 1 else word.len], 10);
        try hashmapPutOrAdd(&stones[0], num, 1);
    }

    var sum1: usize = 0;
    var sum2: usize = 0;

    const part1_end = try blink(1, 25);
    var iter1 = stones[part1_end ^ 1].iterator();
    while (iter1.next()) |stone| {
        sum1 += stone.value_ptr.*;
    }

    const part2_end = try blink(part1_end, 50);
    var iter2 = stones[part2_end ^ 1].iterator();
    while (iter2.next()) |stone| {
        sum2 += stone.value_ptr.*;
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
