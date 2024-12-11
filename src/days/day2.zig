const std = @import("std");

const Order = enum(u8) {
    unknown,
    ascending,
    descending,
};

pub fn day2(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var fin_buffer: [128]u8 = undefined;

    var sum1: u32 = 0;
    var sum2: u32 = 0;

    var line_list = std.ArrayList(i16).init(allocator);

    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (line_list.clearRetainingCapacity()) { // Part Two
        var safe = true;

        var token_stream = std.mem.tokenizeAny(u8, line, " ");

        while (token_stream.next()) |word| {
            try line_list.append(try std.fmt.parseInt(i16, word, 10));
        }

        // Part One
        var previous = line_list.items[0];
        var line_order: Order = .unknown;

        for (line_list.items[1..]) |num| {
            const current: i16 = num;
            defer previous = current;

            const difference: i16 = current - previous;
            if (@abs(difference) == 0 or @abs(difference) > 3) { // If repeat or >3 diff
                safe = false;
                break;
            }

            const last_order = if (difference > 0) Order.ascending else Order.descending;
            if (line_order == .unknown) { // Determine order on first pair
                line_order = last_order;
            } else if (line_order != last_order) { // If obey order
                safe = false;
                break;
            }
        }
        if (safe) {
            sum1 += 1;
            sum2 += 1;
            continue;
        }

        // Part Two
        escape_for: for (0..line_list.items.len) |i| {
            safe = false;
            const start_index: usize = if (i == 0) 1 else 0;

            previous = line_list.items[start_index];
            line_order = .unknown;

            for (line_list.items[start_index + 1 ..], (start_index + 1)..) |num, j| {
                if (i == j) continue;
                const current: i16 = num;
                defer previous = current;

                const difference: i16 = current - previous;
                if (@abs(difference) == 0 or @abs(difference) > 3) continue :escape_for; // If repeat or >3 diff

                const last_order = if (difference > 0) Order.ascending else Order.descending;

                if (line_order == .unknown) { // Determine order on first pair
                    line_order = last_order;
                } else if (line_order != last_order) { // If obey order
                    continue :escape_for;
                }
            }
            safe = true;
            break;
        }

        if (safe) {
            sum2 += 1;
        }
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
