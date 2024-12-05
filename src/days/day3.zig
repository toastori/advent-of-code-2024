const std = @import("std");

const mul_check: []const u8 = "mul(";
const do_check: []const u8 = "do()";
const dont_check: []const u8 = "don't()";

pub fn day3(fin: *const std.io.AnyReader) !void {
    var sum1: u32 = 0;
    var sum2: u32 = 0;

    var stream: [6]u8 = undefined;
    var valid_stream: []u8 = stream[0..0];
    var is_mul = false;

    var is_enabled: bool = true;
    var d: bool = false;
    var multi_usage_index: usize = 0;

    while (fin.readByte() catch null) |c| {
        // multi_usage_index here is for counting mul_check or d_check index
        if (d) {
            const current_d = if (is_enabled) dont_check else do_check;
            const can_d = c == current_d[multi_usage_index];
            if (!can_d) {
                d = c != 'd';
                multi_usage_index = if (c == 'm' or c == 'd') 1 else 0;
            } else if (multi_usage_index == (current_d.len - 1)) {
                is_enabled = !is_enabled;
                multi_usage_index = 0;
                d = false;
                continue;
            } else {
                multi_usage_index += 1;
                continue;
            }
        } else if (!is_mul) {
            const can_mul = c == mul_check[multi_usage_index];
            if (!can_mul) {
                d = c == 'd';
                multi_usage_index = if (c == 'm' or c == 'd') 1 else 0;
            } else if (multi_usage_index == 3) {
                is_mul = true;
                multi_usage_index = 0;
            } else {
                multi_usage_index += 1;
            }
            continue;
        }

        // multi_usage_index here is for comma index
        if (c == ')') {
            if (multi_usage_index != 0 and multi_usage_index != valid_stream.len) {
                const mul_result = (try std.fmt.parseInt(u32, valid_stream[0..multi_usage_index], 10)) * (try std.fmt.parseInt(u32, valid_stream[multi_usage_index..], 10));
                sum1 += mul_result;
                if (is_enabled) sum2 += mul_result;
            }
            is_mul = false;
            multi_usage_index = 0;
            valid_stream = stream[0..0];
        } else if (c == ',') {
            if (multi_usage_index != 0 or valid_stream.len == 0) {
                is_mul = false;
                valid_stream = stream[0..0];
            } else {
                multi_usage_index = valid_stream.len;
            }
        } else if ((c >= '0' and c <= '9') and valid_stream.len < 6) {
            stream[valid_stream.len] = c;
            valid_stream = stream[0..(valid_stream.len + 1)];
        } else {
            multi_usage_index = if (c == 'm' or c == 'd') 1 else 0; // mul_check index
            d = c == 'd';
            is_mul = false;
            valid_stream = stream[0..0];
        }
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
