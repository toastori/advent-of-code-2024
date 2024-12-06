const std = @import("std");

var map_height: usize = 0;
var map_width: usize = 0;

const DirectionEncode = packed struct {
    up: bool = false,
    right: bool = false,
    down: bool = false,
    left: bool = false,
    pad1: bool = false,
    pad2: bool = false,
    pad3: bool = false,
    is_de: bool = true,

    fn isEncoding(c: u8) ?DirectionEncode {
        return if (@as(@This(), @bitCast(c)).is_de) @bitCast(c) else null;
    }
};

const Direction = enum(u2) {
    up = 0,
    right = 1,
    down = 2,
    left = 3,

    fn fromIndicator(c: u8) @This() {
        return switch (c) {
            '^' => .up,
            '>' => .right,
            'v' => .down,
            else => .left,
        };
    }

    fn in(self: @This(), encoding: DirectionEncode) bool {
        return switch (self) {
            .up => encoding.up,
            .right => encoding.right,
            .down => encoding.down,
            .left => encoding.left,
        };
    }

    fn inC(self: @This(), c: u8) bool {
        return if (DirectionEncode.isEncoding(c)) |code| self.in(code) else false;
    }

    fn toEncoding(self: @This()) DirectionEncode {
        return switch (self) {
            .up => .{ .up = true },
            .right => .{ .right = true },
            .down => .{ .down = true },
            .left => .{ .left = true },
        };
    }

    fn addEncoding(self: @This(), encoding: DirectionEncode) DirectionEncode {
        var result = encoding;
        switch (self) {
            .up => result.up = true,
            .right => result.right = true,
            .down => result.down = true,
            .left => result.left = true,
        }
        return result;
    }

    fn addChar(self: @This(), c: u8) u8 {
        const temp = self.toEncoding();
        c |= @bitCast(temp);

        return c;
    }

    fn turnRight(self: @This()) @This() {
        return @enumFromInt(@intFromEnum(self) +% 1);
    }

    fn toIndicator(self: @This()) u8 {
        return switch (self) {
            .up => '^',
            .right => '>',
            .down => 'v',
            .left => '<',
        };
    }
};

const Coord = struct {
    x: usize,
    y: usize,

    fn outOfBounds(self: @This()) bool {
        return self.x >= map_width or self.y >= map_height;
    }

    fn toIndex(self: @This()) usize {
        return self.y * map_width + self.x;
    }
};

const Guard = struct {
    x: usize,
    y: usize,
    direction: Direction,

    fn init(x: usize, y: usize, indicator: u8) @This() {
        return .{
            .x = x,
            .y = y,
            .direction = Direction.fromIndicator(indicator),
        };
    }

    fn coord(self: @This()) Coord {
        return .{ .x = self.x, .y = self.y };
    }

    fn walk(self: *@This()) void {
        const front = self.frontCoord();
        self.x = front.x;
        self.y = front.y;
    }

    fn turnRight(self: *@This()) void {
        self.direction = self.direction.turnRight();
    }

    fn frontCoord(self: @This()) Coord {
        return switch (self.direction) {
            .up => .{ .x = self.x, .y = self.y -% 1 },
            .right => .{ .x = self.x + 1, .y = self.y },
            .down => .{ .x = self.x, .y = self.y + 1 },
            .left => .{ .x = self.x -% 1, .y = self.y },
        };
    }
};

fn solveMapBase(guard_instance: Guard, map: *std.ArrayList(u8)) !u32 {
    var virtualMap = try std.ArrayList(u8).initCapacity(map.allocator, map.items.len);

    var sum2: u32 = 0;
    var guard = guard_instance;

    while (!guard.coord().outOfBounds()) {
        if (!guard.frontCoord().outOfBounds() and
            map.items[guard.frontCoord().toIndex()] == '#')
        {
            guard.turnRight();

            if (DirectionEncode.isEncoding(map.items[guard.coord().toIndex()])) |code| {
                map.items[guard.coord().toIndex()] = @bitCast(guard.direction.addEncoding(code));
            } else {
                map.items[guard.coord().toIndex()] = @bitCast(guard.direction.toEncoding());
            }
        } else {
            if (DirectionEncode.isEncoding(map.items[guard.coord().toIndex()]) == null) map.items[guard.coord().toIndex()] = 'X';

            if (!guard.frontCoord().outOfBounds()) { // Part 2
                const front_coord = guard.frontCoord();
                if (map.items[front_coord.toIndex()] == '.') {
                    virtualMap.appendSliceAssumeCapacity(map.items);
                    defer virtualMap.clearRetainingCapacity();

                    virtualMap.items[front_coord.toIndex()] = '#';
                    if (solveMapMakeStuck(guard, virtualMap.items)) sum2 += 1;
                }
            }
            guard.walk();
        }
    }
    return sum2;
}

fn solveMapMakeStuck(guard_instance: Guard, map: []u8) bool {
    var guard = guard_instance;
    while (!guard.coord().outOfBounds()) {
        const coord = guard.coord();

        if (guard.direction.turnRight().inC(map[coord.toIndex()])) {
            return true;
        } else if (!guard.frontCoord().outOfBounds() and
            map[guard.frontCoord().toIndex()] == '#')
        {
            guard.turnRight();
            if (DirectionEncode.isEncoding(map[coord.toIndex()])) |code| {
                map[coord.toIndex()] = @bitCast(guard.direction.addEncoding(code));
            } else {
                map[coord.toIndex()] = @bitCast(guard.direction.toEncoding());
            }
            continue;
        }
        guard.walk();
    }
    return false;
}

pub fn day6(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var sum1: u32 = 0;
    var sum2: u32 = 0;

    var fin_buffer: [160]u8 = undefined;

    var map = std.ArrayList(u8).init(allocator);

    var guard: Guard = undefined;
    var guard_found = false;

    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (map_height += 1) { // Read Map
        try map.appendSlice(line);
        if (guard_found) continue;

        for (line, 0..) |c, i| {
            if (c == '.' or c == '#') continue;

            map_width = line.len;
            guard_found = true;
            guard = Guard.init(i, map_height, c);
            map.items[map_height * map_width + i] = @bitCast(Direction.fromIndicator(c).toEncoding());
            break;
        }
    }

    sum2 = try solveMapBase(guard, &map);

    for (map.items) |c| { // Part One
        sum1 += if (c != '.' and c != '#') 1 else 0;
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
