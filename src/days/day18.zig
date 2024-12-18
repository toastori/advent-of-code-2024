const std = @import("std");

const map_width = 71;
const map_height = 71;

const goal = Vec2{ .x = map_width - 1, .y = map_height - 1 };

const part1_fallen = 1024 - 1;

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
    x: usize,
    y: usize,

    fn eql(self: @This(), other: @This()) bool {
        return self.x == other.x and self.y == other.y;
    }

    fn valid(self: @This()) bool {
        return self.x < map_width and self.y < map_height;
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
};

fn map_reset(template: [][map_width]u16, map: [][map_width]u16) void {
    for (map, template) |*m, *t| {
        @memcpy(m, t);
    }
}

fn run(allocator: std.mem.Allocator, map: [][map_width]u16, falls: u16) !usize {
    var commands = try std.ArrayList(Vec2).initCapacity(allocator, map_width * map_height / 2);
    defer commands.deinit();

    const fallen_limit: u16 = std.math.maxInt(u16) - falls;

    commands.appendAssumeCapacity(.{ .x = 0, .y = 0 });
    map[0][0] = 1;

    var cmd_idx: usize = 0;
    while (cmd_idx < commands.items.len) : (cmd_idx += 1) {
        const cmd = commands.items[cmd_idx];
        const here = map[cmd.y][cmd.x];

        for (Direction.directions) |d| {
            const d_idx = cmd.direction(d);
            const there = map[d_idx.y][d_idx.x];

            if (d_idx.eql(goal)) return here;
            if (!d_idx.valid() or there -% 1 <= here or there >= fallen_limit) continue;

            map[d_idx.y][d_idx.x] = here + 1;
            try commands.append(d_idx);
        }
    }
    return 0;
}

pub fn day18(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var map: [map_height][map_width]u16 = undefined;
    var map_template: [map_height][map_width]u16 = [_][map_width]u16{[_]u16{0} ** map_width} ** map_height;

    var falls = try std.ArrayList(Vec2).initCapacity(allocator, 4096);
    defer falls.deinit();

    var fin_buffer: [8]u8 = undefined;
    var fallen_i: u16 = 0;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (fallen_i += 1) {
        var tok = std.mem.tokenizeAny(u8, line, ",");
        const x = try std.fmt.parseInt(usize, tok.next().?, 10);
        const y = try std.fmt.parseInt(usize, tok.next().?, 10);
        try falls.append(.{ .x = x, .y = y });
        map_template[y][x] = std.math.maxInt(u16) - fallen_i;
    }

    map_reset(&map_template, &map);
    const sum1 = try run(allocator, &map, part1_fallen);
    std.debug.print("Part One: {d}\n", .{sum1});

    var bs_start: usize = 0;
    var bs_end: usize = falls.items.len - 1;

    while (bs_start != bs_end and bs_start + 1 != bs_end) {
        const fallen: usize = if ((bs_start + bs_end) % 2 == 0) (bs_start + bs_end) >> 1 else ((bs_start + bs_end) >> 1) + 1;
        map_reset(&map_template, &map);
        const result = try run(allocator, &map, @intCast(fallen));
        if (result == 0) {
            bs_end = fallen;
        } else {
            bs_start = fallen;
        }
    }
    const sum2: Vec2 = falls.items[bs_end];

    std.debug.print("Part Two: {d},{d}\n", .{ sum2.x, sum2.y });
}
