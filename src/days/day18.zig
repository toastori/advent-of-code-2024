const std = @import("std");

const map_width = 71;
const map_height = 71;

const goal = Vec2{ .x = map_width - 1, .y = map_height - 1 };

const fallen = 1024;

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

fn run(allocator: std.mem.Allocator, map: [][map_width]u16) !usize {
    var commands = try std.ArrayList(Vec2).initCapacity(allocator, map_width * map_height / 2);
    defer commands.deinit();

    commands.appendAssumeCapacity(.{ .x = 0, .y = 0 });
    map[0][0] = 1;

    var cmd_idx: usize = 0;
    while (cmd_idx < commands.items.len) : (cmd_idx += 1) {
        const cmd = commands.items[cmd_idx];
        const here = map[cmd.y][cmd.x];

        for (Direction.directions) |d| {
            const d_idx = cmd.direction(d);
            if (!d_idx.valid() or map[d_idx.y][d_idx.x] >= here) continue;
            if (d_idx.eql(goal)) return here;
            map[d_idx.y][d_idx.x] = here + 1;
            try commands.append(d_idx);
        }
    }
    return 0;
}

pub fn day18(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var map: [map_height][map_width]u16 = undefined;
    var map_template: [map_height][map_width]u16 = [_][map_width]u16{[_]u16{0} ** map_width} ** map_height;

    var fin_buffer: [8]u8 = undefined;
    for (0..fallen) |_| {
        var tok = std.mem.tokenizeAny(u8, fin.readUntilDelimiter(&fin_buffer, '\n') catch break, ",");
        const x = try std.fmt.parseInt(usize, tok.next().?, 10);
        const y = try std.fmt.parseInt(usize, tok.next().?, 10);
        map_template[y][x] = std.math.maxInt(u16);
    }

    map_reset(&map_template, &map);
    const sum1 = try run(allocator, &map);

    var sum2: Vec2 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
        var tok = std.mem.tokenizeAny(u8, line, ",");
        const x = try std.fmt.parseInt(usize, tok.next().?, 10);
        const y = try std.fmt.parseInt(usize, tok.next().?, 10);
        map_template[y][x] = std.math.maxInt(u16);
        map_reset(&map_template, &map);
        if (try run(allocator, &map) == 0) {
            sum2 = .{ .x = x, .y = y };
            break;
        }
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d},{d}\n", .{ sum2.x, sum2.y });
}
