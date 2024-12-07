const std = @import("std");

const OpWithConcatSequence = struct {
    arr: [12]u2,
    len: usize,

    fn initAllAdd(len: usize) @This() {
        return .{
            .arr = [_]u2{0} ** 12,
            .len = len,
        };
    }

    fn inc(self: *@This()) bool {
        for (&self.arr) |*op| {
            if (op.* == 2) {
                op.* = 0;
            } else {
                op.* += 1;
                break;
            }
        }
        return self.arr[self.len] == 0;
    }

    // Return `result` and whether concat involved in calculation
    fn solve(self: @This(), nums: []const u64) u64 {
        var result = nums[0];
        for (nums[1..], self.arr[0..self.len]) |num, op| {
            switch (op) {
                0 => result += num,
                1 => result *= num,
                else => {
                    const num_f32: f32 = @floatFromInt(num);
                    result = result * (10 * std.math.pow(u64, 10, @intFromFloat(@log10(num_f32)))) + num;
                },
            }
        }
        return result;
    }
};

// Original Part One Code
fn solveOpSequence(nums: []const u64, operators: usize) u64 {
    var result = nums[0];
    for (nums[1..], 0..) |num, op_index| {
        switch (operators & (@as(usize, 1) << @intCast(op_index))) {
            0 => result += num,
            else => result *= num,
        }
    }
    return result;
}

pub fn day7(fin: *const std.io.AnyReader) !void {
    var sum1: u64 = 0;
    var sum2: u64 = 0;

    var fin_buffer: [128]u8 = undefined;

    main_while: while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
        var tokenizer = std.mem.tokenizeAny(u8, line, ": ");

        const result = try std.fmt.parseInt(u64, tokenizer.next().?, 10);

        var nums: [12]u64 = undefined;
        var nums_count: usize = 0;

        while (tokenizer.next()) |word| : (nums_count += 1) {
            nums[nums_count] = try std.fmt.parseInt(u64, word, 10);
        }

        const nums_slice = nums[0..nums_count];

        const operator_count: usize = nums_count - 1;

        // Original Part One Code
        const op_cap: usize = @as(usize, 1) << @intCast(operator_count);
        for (0..op_cap) |op_sequence| {
            if (solveOpSequence(nums_slice, op_sequence) == result) {
                sum1 += result;
                sum2 += result;
                continue :main_while;
            }
        }

        // Part Two
        var op_cat_sequence = OpWithConcatSequence.initAllAdd(operator_count);
        while (blk: {
            if (op_cat_sequence.solve(nums_slice) == result) {
                // if (calc.no_concat) sum1 += result;
                sum2 += result;
                break :blk false;
            }
            break :blk op_cat_sequence.inc();
        }) {}
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
