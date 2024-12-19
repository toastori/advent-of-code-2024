const std = @import("std");

var unlimited: std.ArrayList([9]u8) = undefined;

pub fn day19(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    unlimited = try std.ArrayList([9]u8).initCapacity(allocator, 64);
    {
        var fin_buffer: [3000]u8 = undefined;
        if (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
            var tok = std.mem.tokenizeAny(u8, line, ", ");
            while (tok.next()) |word| {
                try unlimited.append([_]u8{0} ** 9);
                @memcpy(unlimited.items[unlimited.items.len - 1][0..word.len], word);
            }
        } else return;
        try fin.skipUntilDelimiterOrEof('\n');
    }

    var sum1: u32 = 0;
    var sum2: usize = 0;

    var fin_buffer: [128]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
        var added1 = false;
        var counts = [_]usize{0} ** 64;
        var indicator: std.bit_set.IntegerBitSet(64) = std.bit_set.IntegerBitSet(64).initEmpty();
        indicator.set(0);
        counts[0] = 1;

        for (0..line.len) |i| {
            if (!indicator.isSet(i)) continue;
            const max_len: usize = line.len - i;
            towels_loop: for (unlimited.items) |t| {
                const towel: [*]const u8 = &t;

                var towel_idx: usize = 0;
                while (towel[towel_idx] != 0) : (towel_idx += 1) {
                    if (max_len < towel_idx or line[i + towel_idx] != towel[towel_idx]) {
                        continue :towels_loop;
                    }
                }

                if (i + towel_idx != line.len) { // not whole string
                    counts[i + towel_idx] += counts[i];
                    indicator.set(i + towel_idx);
                    continue;
                }

                // matched whole string
                if (indicator.isSet(i)) sum2 += counts[i];
                indicator.unset(i);
                if (!added1) {
                    sum1 += 1;
                    added1 = true;
                }
            }
        }
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
