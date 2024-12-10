const std = @import("std");

var map_height: u32 = 0;
var map_width: u32 = 0;

const Vec2 = struct {
    x: u32,
    y: u32,

    fn up(self: @This()) @This() {
        return .{ .x = self.x, .y = self.y + 1 };
    }
    fn right(self: @This()) @This() {
        return .{ .x = self.x + 1, .y = self.y };
    }
    fn down(self: @This()) @This() {
        return .{ .x = self.x, .y = self.y -% 1 };
    }
    fn left(self: @This()) @This() {
        return .{ .x = self.x -% 1, .y = self.y };
    }

    fn toIndex(self: @This()) usize {
        const xsize: usize = @intCast(self.x);
        const ysize: usize = @intCast(self.y);
        return ysize * map_width + xsize;
    }

    fn outOfBounds(self: @This()) bool {
        return self.x >= map_width or self.y >= map_height;
    }
};

var starting_pt: std.ArrayList(Vec2) = undefined;
var map: std.ArrayList(u8) = undefined;
var path: std.DynamicBitSet = undefined;

fn part1(prev: u8, pos: Vec2) u32 {
    if (pos.outOfBounds()) return 0;
    const index = pos.toIndex();
    const here = map.items[index];
    if (here != prev + 1 or path.isSet(index)) return 0;
    if (here != prev + 1) return 0;
    path.set(index);
    if (here == '9') return 1;
    return part1(here, pos.up()) +
        part1(here, pos.right()) +
        part1(here, pos.down()) +
        part1(here, pos.left());
}

fn part2(prev: u8, pos: Vec2) u32 {
    if (pos.outOfBounds()) return 0;
    const index = pos.toIndex();
    const here = map.items[index];
    if (here != prev + 1) return 0;
    if (here == '9') return 1;
    return part2(here, pos.up()) +
        part2(here, pos.right()) +
        part2(here, pos.down()) +
        part2(here, pos.left());
}


pub fn day10(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var sum1: u32 = 0;
    var sum2: u32 = 0;

    var fin_buffer: [64]u8 = undefined;
    map = try std.ArrayList(u8).initCapacity(allocator, 4096);
    starting_pt = try std.ArrayList(Vec2).initCapacity(allocator, 64);

    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (map_height += 1) {
        map.appendSliceAssumeCapacity(line);
        for (line, 0..) |node, i| {
            const iu32: u32 = @intCast(i);
            if (node == '0') {
                try starting_pt.append(.{ .x = iu32, .y = map_height });
            }
        }
    }
    map_width = @as(u32, @intCast(map.items.len)) / map_height;

    path = try std.DynamicBitSet.initEmpty(allocator, map.items.len);
    for (starting_pt.items) |start| { // Part One
        const routes = part1('0' - 1, start);
        sum1 += routes;
        path.setRangeValue(.{ .start = 0, .end = map.items.len }, false);
    }

    for (starting_pt.items) |start| { // Part Two
        const routes = part2('0' - 1, start);
        sum2 += routes;
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
