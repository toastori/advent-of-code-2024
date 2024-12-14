const std = @import("std");

const map_height = 103;
const map_width = 101;
const seconds = 100;

const Robot = struct {
    x: i32,
    y: i32,
    v_x: i32,
    v_y: i32,

    fn run(self: *@This()) void {
        self.x = @mod(self.x + self.v_x, map_width);
        self.y = @mod(self.y + self.v_y, map_height);
    }

    fn toIndex(self: @This()) usize {
        return @intCast(self.y * map_width + self.x);
    }
};

fn quadent(x: i32, y: i32) ?usize {
    if (x == map_width / 2 or y == map_height / 2) return null;
    if (x < map_width / 2 and y < map_height / 2) {
        return 1;
    } else if (x > map_width / 2 and y < map_height / 2) {
        return 0;
    } else if (x < map_width / 2 and y > map_height / 2) {
        return 2;
    } else {
        return 3;
    }
}

pub fn day14(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var robots = try std.ArrayList(Robot).initCapacity(allocator, 500);
    var quadrent_bots = [4]u32{ 0, 0, 0, 0 };
    var fin_buffer: [24]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
        var tokenizer = std.mem.tokenizeAny(u8, line, "pv=, ");

        const pos_x = try std.fmt.parseInt(i32, tokenizer.next() orelse break, 10);
        const pos_y = try std.fmt.parseInt(i32, tokenizer.next() orelse break, 10);
        const v_x = try std.fmt.parseInt(i32, tokenizer.next() orelse break, 10);
        const v_y = try std.fmt.parseInt(i32, tokenizer.next() orelse break, 10);

        try robots.append(.{ .x = pos_x, .y = pos_y, .v_x = v_x, .v_y = v_y });

        const final_x = @mod(pos_x + v_x * seconds, map_width);
        const final_y = @mod(pos_y + v_y * seconds, map_height);

        const final_quadrent = quadent(final_x, final_y) orelse continue;
        quadrent_bots[final_quadrent] += 1;
    }

    const sum1: u32 = quadrent_bots[0] * quadrent_bots[1] * quadrent_bots[2] * quadrent_bots[3];

    std.debug.print("Part One: {d}\n", .{sum1});

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.BufferedWriter(6144, @TypeOf(stdout_file)){ .unbuffered_writer = stdout_file };
    const stdout = bw.writer();

    var sum2: u32 = 0;
    var map = try std.DynamicBitSet.initEmpty(allocator, map_width * map_height);

    while (blk: {
        var hav_line = false;
        for (robots.items) |robot| {
            map.set(robot.toIndex());
        }
        outer_for: for (38 - 4..38 + 4) |y| {
            var num_in_row: u8 = 0;
            for (0..map_width) |x| {
                if (map.isSet(y * map_width + x)) {
                    num_in_row += 1;
                } else {
                    num_in_row = 0;
                }
                if (num_in_row > 25) {
                    hav_line = true;
                    break :outer_for;
                }
            }
        }
        if (hav_line) {
            var idx: usize = 0;
            for (0..map_height) |_| {
                for (0..map_width) |_| {
                    try stdout.writeByte(if (map.isSet(idx)) @intCast('#') else @intCast('.'));
                    try stdout.writeByte(' ');
                    idx += 1;
                }
                try stdout.writeByte('\n');
            }
            _ = try stdout.write(try std.fmt.bufPrint(&fin_buffer, "Part Two: {d}\n", .{sum2}));
            try bw.flush();
        }
        sum2 += 1;
        for (robots.items) |*robot| {
            robot.run();
        }
        map.setRangeValue(.{ .start = 0, .end = map_width * map_height }, false);
        break :blk !hav_line;
    }) {}
}
