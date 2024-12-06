const std = @import("std");

pub fn day1(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var file_buffer: [15]u8 = undefined;

    var left_list = std.ArrayList(u32).init(allocator);
    var right_list = std.ArrayList(u32).init(allocator);

    while (try fin.readUntilDelimiterOrEof(&file_buffer, '\n')) |line| {
        const left = line[0..5];
        const right = line[8..13];

        try left_list.append(try std.fmt.parseInt(u32, left, 10));
        try right_list.append(try std.fmt.parseInt(u32, right, 10));
    }

    std.mem.sort(u32, left_list.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, right_list.items, {}, comptime std.sort.asc(u32));

    // Part 2
    var right_count_map = std.AutoHashMap(u32, u16).init(allocator);

    var sum1: u32 = 0;
    // Part 2
    var right_value = right_list.items[0];
    var right_count: u16 = 0;

    for (left_list.items, right_list.items) |left, right| {
        sum1 += @max(left, right) - @min(left, right);

        // Part 2
        if (right != right_value) {
            try right_count_map.put(right_value, right_count);
            right_value = right;
            right_count = 1;
        } else {
            right_count += 1;
        }
    }
    // Part 2
    try right_count_map.put(right_value, right_count);

    std.debug.print("Part One: {d}\n", .{sum1});

    // Part 2
    var sum2: u32 = 0;
    for (left_list.items) |left| {
        sum2 += left * @as(u32, @intCast(right_count_map.get(left) orelse 0));
    }

    std.debug.print("Part Two: {d}\n", .{sum2});
}
