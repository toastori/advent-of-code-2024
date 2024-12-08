const std = @import("std");

var map_height: i32 = 0;
var map_width: i32 = 0;

const Vec2 = struct {
    x: i32,
    y: i32,

    /// Subtract assign `-=`
    fn subSet(self: *@This(), other: @This()) void {
        self.x -= other.x;
        self.y -= other.y;
    }

    /// Addition assign `+=`
    fn addSet(self: *@This(), other: @This()) void {
        self.x += other.x;
        self.y += other.y;
    }

    /// Check if the position is inside map
    fn inside(self: @This()) bool {
        return self.x >= 0 and self.y >= 0 and self.x < map_width and self.y < map_height;
    }
};

pub fn day8(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var sum1: u32 = 0;
    var sum2: u32 = 0;

    var fin_buffer: [64]u8 = undefined;

    var antenna_map = std.AutoHashMap(u8, std.ArrayListUnmanaged(Vec2)).init(allocator);
    var antinode_map1 = std.AutoHashMap(Vec2, bool).init(allocator);
    var antinode_map2 = std.AutoHashMap(Vec2, bool).init(allocator);

    // Read file
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (map_height += 1) {
        if (map_width == 0) map_width = @intCast(line.len);
        for (line, 0..) |node, x| {
            const xi: i32 = @intCast(x);
            if (node != '.') {
                if (antenna_map.contains(node)) { // Append to existing arraylist
                    try antenna_map.getPtr(node).?.append(allocator, .{ .x = xi, .y = map_height });
                } else { // New node then make new key (allocate arraylist)
                    try antenna_map.put(node, try std.ArrayListUnmanaged(Vec2).initCapacity(allocator, 2));
                    antenna_map.getPtr(node).?.appendAssumeCapacity(.{ .x = xi, .y = map_height });
                }
            }
        }
    }

    var antenna_iter = antenna_map.iterator();

    while (antenna_iter.next()) |node_type| {
        for (node_type.value_ptr.items, 1..) |node1, i| {
            for (node_type.value_ptr.items[i..]) |node2| {
                const x_diff = node1.x - node2.x;
                const y_diff = node1.y - node2.y;

                var pos1 = Vec2{ .x = node1.x + x_diff, .y = node1.y + y_diff };
                var pos2 = Vec2{ .x = node2.x - x_diff, .y = node2.y - y_diff };

                // Part One
                if (pos1.inside()) try antinode_map1.put(pos1, true); // Extend from node1
                if (pos2.inside()) try antinode_map1.put(pos2, true); // Extend from node2

                // Part Two
                while (blk: { // Extend from node1
                    pos1.subSet(.{ .x = x_diff, .y = y_diff });
                    if (!pos1.inside()) break :blk false;
                    try antinode_map2.put(pos1, true);
                    break :blk true;
                }) {}
                while (blk: { // Extend from node2
                    pos2.addSet(.{ .x = x_diff, .y = y_diff });
                    if (!pos2.inside()) break :blk false;
                    try antinode_map2.put(pos2, true);
                    break :blk true;
                }) {}
            }
        }
    }

    sum1 = antinode_map1.count();
    sum2 = antinode_map2.count();

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
