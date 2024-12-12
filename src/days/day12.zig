const std = @import("std");

var map: std.ArrayList(u32) = undefined;
var map_height: usize = 0;
var map_width: usize = undefined;

fn indexOf(i: usize, j: usize) usize {
    return i * map_width + j;
}

fn indexOfOrNull(i: usize, j: usize) ?usize {
    if (i >= map_height or j >= map_width) return null;
    return i * map_width + j;
}

const Diagnals = enum {
    top_left, // Left, Up
    top_right, // Right, Up
    bot_left, // Left, Bottom
    bot_right, // Right Buttom
};

fn diagIsPoint(i: usize, j: usize, diag: Diagnals) bool {
    const here = map.items[indexOf(i, j)];
    const hori_index = switch (diag) {
        .top_left, .bot_left => indexOfOrNull(i, j -% 1), // Left
        .top_right, .bot_right => indexOfOrNull(i, j + 1), // Right
    };
    const hori_side: u32 = if (hori_index) |idx| map.items[idx] else @intCast(0);

    const vert_index = switch (diag) {
        .top_left, .top_right => indexOfOrNull(i -% 1, j), // Top
        .bot_left, .bot_right => indexOfOrNull(i + 1, j), // Bottom
    };
    const vert_side: u32 = if (vert_index) |idx| map.items[idx] else @intCast(0);

    const diag_corner_index: ?usize = switch (diag) {
        .top_left => indexOfOrNull(i -% 1, j -% 1),
        .top_right => indexOfOrNull(i -% 1, j + 1),
        .bot_left => indexOfOrNull(i + 1, j -% 1),
        .bot_right => indexOfOrNull(i + 1, j + 1),
    };
    const diag_corner: u32 = if (diag_corner_index) |idx| map.items[idx] else @intCast(0);
    return hori_side != here and vert_side != here or
        hori_side == here and vert_side == here and diag_corner != here;
}

const Directions = enum {
    up,
    right,
    down,
    left,
};

const Command = struct {
    from: Directions,
    i: usize,
    j: usize,

    fn toIndex(self: @This()) usize {
        return self.i * map_width + self.j;
    }

    fn indexOfDir(self: @This(), direction: Directions) ?usize {
        return switch (direction) {
            .up => indexOfOrNull(self.i -% 1, self.j),
            .right => indexOfOrNull(self.i, self.j + 1),
            .down => indexOfOrNull(self.i + 1, self.j),
            .left => indexOfOrNull(self.i, self.j -% 1),
        };
    }

    fn isIndexValid(self: @This()) bool {
        return self.i < map_height and self.j < map_width;
    }
};

const ExploreResult = struct {
    area: usize,
    peri: usize,
};

fn explore(allocator: std.mem.Allocator, count: u32, i_index: usize, j_index: usize) !ExploreResult {
    const vegi = map.items[indexOfOrNull(i_index, j_index).?];
    var area: usize = 1;
    var peri: usize = 4;
    map.items[indexOf(i_index, j_index)] = count;

    var command_queue = std.MultiArrayList(Command){};
    if (indexOfOrNull(i_index + 1, j_index)) |_| try command_queue.append(allocator, .{ .from = .up, .i = i_index + 1, .j = j_index });
    if (indexOfOrNull(i_index, j_index + 1)) |_| try command_queue.append(allocator, .{ .from = .left, .i = i_index, .j = j_index + 1 });

    const from = [4]Directions{ .up, .right, .down, .left };
    while (command_queue.popOrNull()) |com| {
        if (map.items[com.toIndex()] != vegi) continue;
        var valid_directions = [4]bool{ true, true, true, true };
        for (from, 0..) |dir, i| {
            if (com.indexOfDir(dir)) |idx| {
                if (map.items[idx] == count) {
                    peri -= 1;
                    valid_directions[i] = false;
                }
            }
        }
        area += 1;
        map.items[com.toIndex()] = count;
        const commands = [4]Command{
            .{ .from = .down, .i = com.i -% 1, .j = com.j },
            .{ .from = .left, .i = com.i, .j = com.j + 1 },
            .{ .from = .up, .i = com.i + 1, .j = com.j },
            .{ .from = .right, .i = com.i, .j = com.j -% 1 },
        };
        for (valid_directions, commands) |valid, next_com| {
            if (!valid) continue;
            peri += 1;
            if (next_com.isIndexValid()) try command_queue.append(allocator, next_com);
        }
    }
    return .{ .area = area, .peri = peri };
}

pub fn day12(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var sum1: usize = 0;
    var sum2: usize = 0;

    map = try std.ArrayList(u32).initCapacity(allocator, 141 * 141);

    var fin_buffer: [160]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (map_height += 1) {
        for (line) |c| {
            map.appendAssumeCapacity(@intCast(c));
        }
    }
    map_width = map.items.len / map_height;

    var counts_area = std.ArrayList(usize).init(allocator);

    var counter: u32 = std.math.maxInt(u7) + 1;
    for (0..map_height) |i| {
        for (0..map_width) |j| {
            if (map.items[indexOf(i, j)] < std.math.maxInt(u7)) { // Explore unexplored node
                const result = try explore(allocator, counter, i, j); // count area and perimiter
                try counts_area.append(result.area);
                sum1 += result.area * result.peri;
                counter += 1;
            }
        }
    }

    var counts_sides = try std.ArrayList(u32).initCapacity(allocator, counts_area.items.len);
    counts_sides.appendNTimesAssumeCapacity(0, counts_area.items.len);

    const diags = [4]Diagnals{ .top_left, .top_right, .bot_left, .bot_right };

    for (0..map_height) |i| {
        for (0..map_width) |j| {
            for (diags) |diag| { // Count corners of each count (area)
                if (diagIsPoint(i, j, diag)) counts_sides.items[@intCast(map.items[indexOf(i, j)] - std.math.maxInt(u7) - 1)] += 1;
            }
        }
    }

    for (counts_area.items, counts_sides.items) |area, side| { // Add up for part2
        sum2 += @intCast(area * side);
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
