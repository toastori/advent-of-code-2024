const std = @import("std");

const WALL = std.math.maxInt(u32);

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

    var commands = std.ArrayList(Deer).init(allocator);
    defer commands.deinit();
    var been = std.AutoHashMap(Vec2, usize).init(allocator); // pos and turn
    defer been.deinit();

    try commands.append(deer);

    var cmd_idx: usize = 0;
    while (cmd_idx < commands.items.len) : (cmd_idx += 1) {
        var this_deer = commands.items[cmd_idx];
        if (this_deer.travel.turns > least_turn) break;
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
                        map.items[this_deer.pos.direction(d).toIndex()] == WALL) continue;
                    try commands.append(.{
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
            if (map.items[this_deer.pos.toIndex()] > @as(u32, @intCast(this_deer.travel.turns + 1)) * 1000 + this_deer.travel.steps) {
                map.items[this_deer.pos.toIndex()] = @intCast((this_deer.travel.turns + 1) * 1000 + this_deer.travel.steps);
            }
            if (map.items[this_deer.front().toIndex()] == WALL) break;
            this_deer.go();
        }
    }
    map.items[goal.toIndex()] = @intCast((least_turn + 2) * 1000 + shortest);
    return shortest + least_turn * 1000;
}

const BestSeatCmd = struct {
    pos: Vec2,
    value: u32,
    direction: Direction,

    fn front(self: @This()) Vec2 {
        return self.pos.direction(self.direction);
    }

    fn go(self: *@This()) void {
        self.pos = self.front();
        self.value -= 1;
    }
};

fn bestSeat(allocator: std.mem.Allocator, goal: Vec2) !usize {
    var good_seat = try std.DynamicBitSet.initEmpty(allocator, map_height * map_width);
    defer good_seat.deinit();
    var commands = try std.ArrayList(BestSeatCmd).initCapacity(allocator, @intCast(map.items[goal.toIndex()] / 1000 * 2));
    defer commands.deinit();

    for (Direction.directions) |d| {
        const d_pos = goal.direction(d);
        if (map.items[d_pos.toIndex()] != map.items[goal.toIndex()] - 1001) continue;

        try commands.append(.{ .direction = d, .pos = d_pos, .value = map.items[d_pos.toIndex()] });
        good_seat.set(d_pos.toIndex());
    }

    var cmd_idx: usize = 0;
    while (cmd_idx < commands.items.len) : (cmd_idx += 1) {
        var com = commands.items[cmd_idx];

        var last = com.pos;

        while (true) {
            var found_intersection = false;
            if (map.items[com.pos.toIndex()] < com.value) {
                for (Direction.directions) |d| {
                    if (com.direction.opposite() == d or com.direction == d or // 0 or 180 deg turn
                        map.items[com.pos.direction(d).toIndex()] > com.value or // more turn
                        map.items[com.pos.direction(d).toIndex()] % 1000 > com.value % 1000) continue; // more steps
                    try commands.append(.{ .direction = d, .pos = com.pos.direction(d), .value = map.items[com.pos.direction(d).toIndex()] });
                }
                found_intersection = true;
            } else if (map.items[com.pos.toIndex()] == 0) {
                found_intersection = true;
            }
            if (found_intersection) {
                if (last.x == com.pos.x) {
                    for (@min(last.y, com.pos.y)..@max(last.y, com.pos.y) + 1) |i| {
                        good_seat.set(i * map_width + last.x);
                    }
                } else {
                    for (@min(last.x, com.pos.x)..@max(last.x, com.pos.x) + 1) |j| {
                        good_seat.set(last.y * map_width + j);
                    }
                }
                last = com.pos;
            }
            if (map.items[com.front().toIndex()] > com.value) break;
            com.go();
        }
    }

    return good_seat.count() + 1;
}

pub fn day16(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    map = try std.ArrayList(u32).initCapacity(allocator, 140 * 140);
    var deer: Deer = undefined;
    var found_d = false;
    var goal: Vec2 = undefined;
    var found_g = false;

    var fin_buffer: [160]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (map_height += 1) {
        for (line, 0..) |c, i| {
            try map.append(if (c == '#') @intCast(WALL) else @intCast(WALL - 1));
            if (found_d and found_g) continue;
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
                map.items[map.items.len - 1] = 0;
                continue;
            } else if (c == 'E') {
                found_g = true;
                goal = .{ .x = @intCast(i), .y = @intCast(map_height) };
                continue;
            }
        }
    }
    map_width = map.items.len / map_height;

    const sum1 = try solveMap(allocator, deer, goal);

    const sum2 = try bestSeat(allocator, goal);

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
