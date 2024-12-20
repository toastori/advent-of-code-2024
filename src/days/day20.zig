const std = @import("std");

const WALL = std.math.maxInt(u31);

var map: std.ArrayList(u32) = undefined;
var map_height: usize = 0;
var map_width: usize = undefined;

const Direction = enum {
    up,
    right,
    down,
    left,

    const directions = [4]Direction{ .up, .right, .down, .left };

    fn opposite(self: @This()) @This() {
        return switch (self) {
            .up => .down,
            .down => .up,
            .right => .left,
            .left => .right,
        };
    }
};

const Vec2 = struct {
    x: u32,
    y: u32,

    fn eql(self: @This(), other: @This()) bool {
        return self.x == other.x and self.y == other.y;
    }

    fn direction(self: @This(), dir: Direction) @This() {
        return switch (dir) {
            .up => self.up(),
            .right => self.right(),
            .down => self.down(),
            .left => self.left(),
        };
    }

    fn up(self: @This()) @This() {
        return .{ .x = self.x, .y = self.y -% 1 };
    }
    fn right(self: @This()) @This() {
        return .{ .x = self.x + 1, .y = self.y };
    }
    fn down(self: @This()) @This() {
        return .{ .x = self.x, .y = self.y + 1 };
    }
    fn left(self: @This()) @This() {
        return .{ .x = self.x -% 1, .y = self.y };
    }

    fn toIndex(self: @This()) usize {
        const xsize: usize = @intCast(self.x);
        const ysize: usize = @intCast(self.y);
        return ysize * map_width + xsize;
    }
};

fn run(start: Vec2, end: Vec2) u32 {
    var result: u32 = 0;

    var counter: u32 = 1;
    var here_pos = start;
    while (true) : (counter += 1) {
        var next_pos: Vec2 = undefined;

        for (Direction.directions) |d| {
            const d_pos = here_pos.direction(d);
            const there = map.items[d_pos.toIndex()];

            if (there == WALL) {
                map.items[d_pos.toIndex()] += counter;
            } else if (there > WALL) {
                if (there <= counter + WALL - 100 - 2) {
                    map.items[here_pos.toIndex()] = 1;
                    result += 1;
                }
            } else if (there == 0) {
                next_pos = d_pos;
            }
        }
        if (here_pos.eql(end)) return result;
        map.items[here_pos.toIndex()] += 1;
        here_pos = next_pos;
    }
    return 0;
}

pub fn day20(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    map = try std.ArrayList(u32).initCapacity(allocator, 140 * 140);
    var start: Vec2 = undefined;
    var end: Vec2 = undefined;

    var fin_buffer: [160]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (map_height += 1) {
        for (line, 0..) |c, i| {
            try map.append(if (c == '#') WALL else 0);
            if (c == 'S') {
                start = .{
                    .x = @intCast(i),
                    .y = @intCast(map_height),
                };
            } else if (c == 'E') {
                end = .{
                    .x = @intCast(i),
                    .y = @intCast(map_height),
                };
            }
        }
    }
    map_width = map.items.len / map_height;

    const sum1 = run(start, end);

    std.debug.print("Part One: {d}\n", .{sum1});
}
