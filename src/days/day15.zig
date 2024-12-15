const std = @import("std");

var map: std.ArrayList(u8) = undefined;
var map2: std.ArrayList(u8) = undefined;
var map_height: usize = 0;
var map_width: usize = undefined;
var map_width2: usize = undefined;

const Vec2 = struct {
    x: u32,
    y: u32,

    fn eql(self: @This(), other: @This()) bool {
        return self.x == other.x and self.y == other.y;
    }

    fn front(self: @This(), command: u8) Vec2 {
        return switch (command) {
            '^' => self.up(),
            '>' => self.right(),
            'v' => self.down(),
            '<' => self.left(),
            else => unreachable,
        };
    }
    fn back(self: @This(), command: u8) Vec2 {
        return switch (command) {
            '^' => self.down(),
            '>' => self.left(),
            'v' => self.up(),
            '<' => self.right(),
            else => unreachable,
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

    fn toIndex2(self: @This()) usize {
        const xsize: usize = @intCast(self.x);
        const ysize: usize = @intCast(self.y);
        return ysize * map_width2 + xsize;
    }
};

const Node = struct {
    item: u8,
    pos: Vec2,
};

var robot: Vec2 = undefined;
var robot2: Vec2 = undefined;

fn pushVert(allocator: std.mem.Allocator, command: u8) !void {
    var nodes_to_check = std.ArrayList(Vec2).init(allocator);
    var nodes_to_push = std.MultiArrayList(Node){};
    var checked_map = std.AutoHashMap(Vec2, void).init(allocator);
    defer nodes_to_check.deinit();
    defer nodes_to_push.deinit(allocator);
    defer checked_map.deinit();

    try nodes_to_check.append(robot2);

    while (nodes_to_check.popOrNull()) |node| {
        const here = map2.items[node.toIndex2()];
        switch (map2.items[node.front(command).toIndex2()]) {
            '#' => return,
            else => |c| {
                try nodes_to_push.append(allocator, .{ .item = here, .pos = node });
                if (c == '.') continue;
            },
        }

        if (!checked_map.contains(node.front(command))) {
            const front_item = map2.items[node.front(command).toIndex2()];
            try nodes_to_check.append(node.front(command));
            try checked_map.put(node.front(command), undefined);
            const also = if (front_item == '[')
                node.front(command).right()
            else
                node.front(command).left();
            try nodes_to_check.append(also);
            try checked_map.put(also, undefined);
        }
    }

    while (nodes_to_push.popOrNull()) |node| {
        if (!checked_map.contains(node.pos.back(command))) map2.items[node.pos.toIndex2()] = '.';
        map2.items[node.pos.front(command).toIndex2()] = node.item;
    }
    robot2 = robot2.front(command);
}

pub fn day15(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    map = try std.ArrayList(u8).initCapacity(allocator, 50 * 50);
    map2 = try std.ArrayList(u8).initCapacity(allocator, 50 * 100);
    var fin_buffer: [1024]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (map_height += 1) { // Read map
        if (line.len == 0) break; // No more map reading
        try map.appendSlice(line);
        for (line, 0..) |c, i| {
            switch (c) {
                '#' => try map2.appendNTimes('#', 2),
                '.', '@' => try map2.appendNTimes('.', 2),
                else => try map2.appendSlice("[]"),
            }
            if (c == '@') {
                robot = .{ .x = @intCast(i), .y = @intCast(map_height) };
                robot2 = .{ .x = @intCast(i * 2), .y = @intCast(map_height) };
            }
        }
    }
    map_width = map.items.len / map_height;
    map.items[robot.toIndex()] = '.';
    map_width2 = map_width * 2;

    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
        for (line) |command| {
            var can_move = true;
            const front = robot.front(command);
            switch (map.items[front.toIndex()]) {
                '.' => {
                    robot = front;
                    can_move = false;
                },
                '#' => {
                    can_move = false;
                },
                else => {},
            }
            var can_move2 = true;
            const front2 = robot2.front(command);
            switch (map2.items[front2.toIndex2()]) {
                '.' => {
                    robot2 = front2;
                    can_move2 = false;
                },
                '#' => {
                    can_move2 = false;
                },
                else => {},
            }

            // Actually Moving Boxes
            if (can_move) {
                var next_front = front.front(command);
                while (map.items[next_front.toIndex()] != '#') : (next_front = next_front.front(command)) { // Hit wall then do nothing
                    if (map.items[next_front.toIndex()] != '.') continue; // Move box if found space

                    map.items[next_front.toIndex()] = 'O';
                    map.items[front.toIndex()] = '.';
                    robot = front;
                    break; // no more loop if moved
                }
            }

            // Visualization
            // for (0..map_height) |i| {
            //     for (0..map_width2) |j| {
            //         if (i * map_width2 + j != robot2.toIndex2()) {
            //             std.debug.print("{c}", .{map2.items[i * map_width2 + j]});
            //         } else std.debug.print("{c}", .{command});
            //     }
            //     std.debug.print("\n", .{});
            // }
            // std.time.sleep(500 * std.time.ns_per_ms);

            if (!can_move2) continue;
            if (command == '>' or command == '<') { // Horizontal
                var next_front = front2.front(command);
                while (map2.items[next_front.toIndex2()] != '#') : (next_front = next_front.front(command)) { // Hit wall then do nothing
                    if (map2.items[next_front.toIndex2()] != '.') continue; // Move box if found space
                    const box = "[]";
                    var box_index: usize = 0;

                    var start_index = @min(front2.toIndex2() + 1, next_front.toIndex2() + 1);
                    if (command == '<') start_index -= 1;
                    var end_index = @max(front2.toIndex2() + 1, next_front.toIndex2() + 1);
                    if (command == '<') end_index -= 1;

                    for (map2.items[start_index..end_index]) |*node| {
                        node.* = box[box_index];
                        box_index ^= 1;
                    }

                    map2.items[front2.toIndex2()] = '.';
                    robot2 = front2;
                    break; // no more loop if moved
                }
            } else {
                try pushVert(allocator, command);
            }
        }
    }

    var sum1: usize = 0;

    for (0..map_height) |i| {
        for (0..map_width) |j| {
            if (map.items[i * map_width + j] == 'O') {
                sum1 += i * 100 + j;
            }
        }
    }

    var sum2: usize = 0;
    for (0..map_height) |i| {
        for (0..map_width2) |j| {
            if (map2.items[i * map_width2 + j] == '[') {
                sum2 += i * 100 + j;
            }
        }
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
