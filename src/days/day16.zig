const std = @import("std");

var map: std.ArrayList(u8) = undefined;
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

const Travel = struct {
    steps: usize,
    turns: usize,
};

const Deer = struct {
    pos: Vec2,
    travel: Travel,
    direction: Direction,

    fn go(self: *@This()) void {
        self.pos = switch (self.direction) {
            .up => self.pos.up(),
            .right => self.pos.right(),
            .down => self.pos.down(),
            .left => self.pos.left(),
        };
        self.travel.steps += 1;
    }

    fn front(self: @This()) Vec2 {
        return switch (self.direction) {
            .up => self.pos.up(),
            .right => self.pos.right(),
            .down => self.pos.down(),
            .left => self.pos.left(),
        };
    }
};

fn solveMap(allocator: std.mem.Allocator, deer: Deer, goal: Vec2) !usize {
    var shortest: usize = std.math.maxInt(usize);
    var least_turn: usize = std.math.maxInt(usize);

    var commands: std.MultiArrayList(Deer) = std.MultiArrayList(Deer){};
    var been = std.AutoHashMap(Vec2, usize).init(allocator); // pos and turn
    defer commands.deinit(allocator);

    try commands.append(allocator, deer);
    while (commands.popOrNull()) |com| {
        var this_deer = com;
        if (this_deer.travel.turns > least_turn) continue;
        while (true) {
            if (this_deer.pos.eql(goal)) {
                if (least_turn < this_deer.travel.turns or
                    shortest < this_deer.travel.steps)
                {
                    break;
                }
                shortest = this_deer.travel.steps;
                least_turn = this_deer.travel.turns;
                break;
            }

            const turn_history = been.get(this_deer.pos);
            const turn: usize = if (turn_history) |entry| @min(entry, least_turn) else least_turn;
            if (this_deer.travel.turns < turn) {
                for (Direction.directions) |d| {
                    if (this_deer.direction.opposite() == d or this_deer.direction == d or
                        map.items[this_deer.pos.direction(d).toIndex()] == '#') continue;
                    try commands.append(allocator, .{
                        .pos = this_deer.pos,
                        .travel = .{
                            .steps = this_deer.travel.steps,
                            .turns = this_deer.travel.turns + 1,
                        },
                        .direction = d,
                    });
                    const entry = try been.getOrPut(this_deer.pos);
                    if (entry.found_existing) {
                        if (entry.value_ptr.* > this_deer.travel.turns + 1) {
                            entry.value_ptr.* = this_deer.travel.turns + 1;
                        }
                    } else {
                        entry.value_ptr.* = this_deer.travel.turns + 1;
                    }
                }
            }
            if (map.items[this_deer.front().toIndex()] == '#') break;
            this_deer.go();
        }
    }

    return shortest + least_turn * 1000;
}

pub fn day16(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    map = try std.ArrayList(u8).initCapacity(allocator, 140 * 140);
    var deer: Deer = undefined;
    var found_d = false;
    var goal: Vec2 = undefined;
    var found_g = false;

    var fin_buffer: [160]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (map_height += 1) {
        try map.appendSlice(line);
        if (!found_d or !found_g) {
            for (line, 0..) |c, i| {
                if (c == 'S') {
                    found_d = true;
                    deer = .{
                        .pos = .{ .x = @intCast(i), .y = @intCast(map_height) },
                        .travel = .{
                            .steps = 0,
                            .turns = 0,
                        },
                        .direction = .right,
                    };
                    continue;
                } else if (c == 'E') {
                    found_g = true;
                    goal = .{ .x = @intCast(i), .y = @intCast(map_height) };
                    continue;
                }
                if (found_d and found_g) break;
            }
        }
    }
    map_width = map.items.len / map_height;

    const sum1 = try solveMap(allocator, deer, goal);

    std.debug.print("Part One: {d}\n", .{sum1});
}
