const std = @import("std");

fn isWhole(num: f64) bool {
    return @as(f64, @floatFromInt(@as(u64, @intFromFloat(num)))) == num;
}

pub fn day13(fin: *const std.io.AnyReader) !void {
    var sum1: f64 = 0;
    var sum2: f64 = 0;

    var fin_buffer: [64]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
        // Button A
        const but_a_x = try std.fmt.parseFloat(f64, line[12..14]);
        const but_a_y = try std.fmt.parseFloat(f64, line[18..20]);

        // Button B
        const line2 = try fin.readUntilDelimiterOrEof(&fin_buffer, '\n') orelse break;
        const but_b_x = try std.fmt.parseFloat(f64, line2[12..14]);
        const but_b_y = try std.fmt.parseFloat(f64, line2[18..20]);

        // Target
        const line3 = try fin.readUntilDelimiterOrEof(&fin_buffer, '\n') orelse break;
        var tokenizer = std.mem.tokenizeAny(u8, line3[7..], "XY=, ");
        const target_x1 = try std.fmt.parseFloat(f64, tokenizer.next().?);
        const target_y1 = try std.fmt.parseFloat(f64, tokenizer.next().?);
        const target_x2 = target_x1 + 10000000000000;
        const target_y2 = target_y1 + 10000000000000;

        // Actual Calc
        const det = but_a_x * but_b_y - but_b_x * but_a_y;
        if (det == 0) {
            _ = fin.readUntilDelimiterOrEof(&fin_buffer, '\n') catch break;
            continue;
        }

        // ax bx  tx
        // ay by  ty

        const det1_1 = target_x1 * but_b_y - target_y1 * but_b_x;
        const det2_1 = but_a_x * target_y1 - but_a_y * target_x1;
        const det1_2 = target_x2 * but_b_y - target_y2 * but_b_x;
        const det2_2 = but_a_x * target_y2 - but_a_y * target_x2;

        const a1 = det1_1 / det;
        const b1 = det2_1 / det;
        const a2 = det1_2 / det;
        const b2 = det2_2 / det;

        if (a1 >= 0 and a1 <= 100 and b1 >= 0 and b1 <= 100 and isWhole(a1) and isWhole(b1)) sum1 += a1 * 3 + b1;
        if (a2 >= 0 and b2 >= 0 and isWhole(a2) and isWhole(b2)) sum2 += a2 * 3 + b2;

        _ = fin.readUntilDelimiterOrEof(&fin_buffer, '\n') catch break;
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
