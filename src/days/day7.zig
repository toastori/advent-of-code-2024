const std = @import("std");

// Return `true` if solvable
fn solveOp(allocator: std.mem.Allocator, nums: []const u64, target: u64, comptime do_concat: bool) !bool {
    var commands = [2]std.ArrayList(u64){ undefined, undefined };
    inline for (&commands) |*cmd_queue| {
        cmd_queue.* = try std.ArrayList(u64).initCapacity(allocator, nums.len * nums.len * if (comptime do_concat) nums.len else 1);
    }
    defer inline for (&commands) |*cmd_queue| {
        cmd_queue.deinit();
    };

    try commands[0].append((nums[0] & std.math.maxInt(u32)));

    var cmd_queue_idx: usize = 0;
    var processed: usize = 1;
    while (processed < nums.len) {
        for (commands[cmd_queue_idx].items) |cmd| {
            const add = cmd + (nums[processed] & std.math.maxInt(u32));
            const mul = cmd * (nums[processed] & std.math.maxInt(u32));

            if (add <= target) try commands[cmd_queue_idx ^ 1].append(add);
            if (mul <= target) try commands[cmd_queue_idx ^ 1].append(mul);

            if (comptime do_concat) {
                const cat = cmd * (nums[processed] >> 32) + (nums[processed] & std.math.maxInt(u32));
                if (cat <= target) try commands[cmd_queue_idx ^ 1].append(cat);
            }
        }
        commands[cmd_queue_idx].clearRetainingCapacity();
        cmd_queue_idx ^= 1;
        processed += 1;
    }

    for (commands[cmd_queue_idx].items) |num| {
        if (num == target) return true;
    }

    return false;
}

pub fn day7(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var sum1: u64 = 0;
    var sum2: u64 = 0;

    var fin_buffer: [128]u8 = undefined;

    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
        var tokenizer = std.mem.tokenizeAny(u8, line, ": ");

        const result = try std.fmt.parseInt(u64, tokenizer.next().?, 10);

        var nums: [12]u64 = undefined;
        var nums_count: usize = 0;

        while (tokenizer.next()) |word| : (nums_count += 1) {
            nums[nums_count] = try std.fmt.parseInt(u64, word, 10);
            nums[nums_count] += std.math.pow(u64, 10, @intCast(word.len)) << 32;
        }

        const nums_slice = nums[0..nums_count];

        // Part One (and if possibly, part two without concat)
        if (try solveOp(allocator, nums_slice, result, false)) {
            sum1 += result;
            sum2 += result;
            continue;
        }

        // Part Two
        if (try solveOp(allocator, nums_slice, result, true)) sum2 += result;
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
