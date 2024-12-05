const std = @import("std");

// Part One
const Lines1 = struct {
    l: [7][160]u8 = [_][160]u8{[_]u8{0} ** 160} ** 7,

    ref: [7]usize = .{ 0, 1, 2, 3, 4, 5, 6 },

    const check: []const u8 = "XMAS";
    // 5 6 7
    // 4 X 0
    // 3 2 1
    //                                        0  1  2  3  4  5   6    7
    const offset1: []const isize = &[_]isize{ 0, 1, 1, 1, 0, -1, -1, -1 };
    const offset2: []const isize = &[_]isize{ 1, 1, 0, -1, -1, -1, 0, 1 };

    fn cycle(self: *Lines1) void {
        const temp = self.ref[0];

        self.ref[0] = self.ref[1];
        self.ref[1] = self.ref[2];
        self.ref[2] = self.ref[3];
        self.ref[3] = self.ref[4];
        self.ref[4] = self.ref[5];
        self.ref[5] = self.ref[6];
        self.ref[6] = temp;
    }

    fn find_xmas(self: Lines1, extra_offset1: isize, uline_len: usize) u32 {
        var result: u32 = 0;

        master_for: for (1..(uline_len + 1)) |index2| { // Current Line find X scope
            if (self.l[self.ref[@intCast(extra_offset1)]][index2] != check[0]) continue;

            const extra_offset2: isize = @intCast(index2);

            var bools = [_]bool{ true, true, true, true, true, true, true, true }; // For Each Direction
            var can: u8 = 8; // Count how many Direction Still Possible to be XMAS

            inline for (check[1..], 1..) |check_c, check_i| { // Check SAM
                const icheck_i: isize = @intCast(check_i);

                inline for (offset1, offset2, 0..) |o1, o2, direction| { // All directions
                    // Index of Next Character on that Direction
                    const i: isize = extra_offset1 + o1 * icheck_i;
                    const j: isize = extra_offset2 + o2 * icheck_i;

                    if (bools[direction]) { // If that Direction still Available
                        if (i >= 0 and i < self.l.len) { // Check Out of Bounds
                            bools[direction] = self.l[self.ref[@intCast(i)]][@intCast(j)] == check_c;
                        } else { // Must not be XMAS when Out of Bounds
                            bools[direction] = false;
                        }
                        if (!bools[direction]) { // Next Character Directly when No More Possible XMAS
                            can -= 1;
                            if (can == 0) continue :master_for;
                        }
                    }
                }
            }

            inline for (bools) |b| {
                if (b) result += 1;
            }
        }

        return result;
    }
};

const Lines2 = struct {
    l: [3][160]u8 = [_][160]u8{[_]u8{0} ** 160} ** 3,

    ref: [3]usize = .{ 0, 1, 2 },

    fn cycle(self: *Lines2) void {
        const temp = self.ref[0];

        self.ref[0] = self.ref[1];
        self.ref[1] = self.ref[2];
        self.ref[2] = temp;
    }

    fn diag_check(top: u8, bottom: u8) bool { // Check if the diag is MAS or SAM
        return top + bottom == 'S' + 'M';
    }

    fn find_xmas(self: Lines2, uline_len: usize) u32 {
        var result: u32 = 0;

        for (2..uline_len) |j| { // Current Line find A scope
            if (self.l[self.ref[1]][j] != 'A') continue; // Not A then Coninue

            const top_left = self.l[self.ref[0]][j - 1];
            const bottom_right = self.l[self.ref[2]][j + 1];
            const left_diag: bool = diag_check(top_left, bottom_right); // Left Diag (\) is MAS or SAM

            const top_right = self.l[self.ref[0]][j + 1];
            const bottom_left = self.l[self.ref[2]][j - 1];
            const right_diag: bool = diag_check(top_right, bottom_left); // Right Diag (/) is MAS or SAM

            if (left_diag and right_diag) result += 1; // Add 1 if both Diag are MAS or SAM
        }

        return result;
    }
};

pub fn day4(fin: *const std.io.AnyReader, file_reader_T: type, file_reader: *const file_reader_T) !void {
    var line_len: usize = 0;

    // Part One
    var lines1 = Lines1{};
    var sum1: u32 = 0;

    for (3..(lines1.l.len - 1)) |i| { // Read 3 lines b4 main loop
        _ = (fin.readUntilDelimiterOrEof(lines1.l[lines1.ref[i]][1..], '\n') catch break);
    }

    while (try fin.readUntilDelimiterOrEof(lines1.l[lines1.ref[6]][1..], '\n')) |line| : (lines1.cycle()) {
        line_len = line.len;
        sum1 += lines1.find_xmas(3, line_len);
    }

    inline for (3..(lines1.l.len - 1)) |i| {
        sum1 += lines1.find_xmas(i, line_len);
    }

    // Part Two
    try file_reader.context.seekTo(0);
    var lines2 = Lines2{};
    var sum2: u32 = 0;

    for (0..(lines2.l.len - 1)) |i| { // Read 2 lines b4 main loop
        _ = (fin.readUntilDelimiterOrEof(lines2.l[lines2.ref[i]][1..], '\n') catch break);
    }

    while (try fin.readUntilDelimiterOrEof(lines2.l[lines2.ref[2]][1..], '\n')) |line| : (lines2.cycle()) {
        line_len = line.len;
        sum2 += lines2.find_xmas(line_len);
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
