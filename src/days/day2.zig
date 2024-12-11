const std = @import("std");

const Order = enum(u8) {
    unknown,
    ascending,
    descending,
};

pub fn day2(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var fin_buffer: [128]u8 = undefined;

    var safe_lines1: u32 = 0;
    var safe_lines2: u32 = 0;

    var line_list = std.ArrayList(i16).init(allocator);

    main_while: while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| : (line_list.clearRetainingCapacity()) { // Part Two
        var safe = false;

        var token_stream = std.mem.tokenizeAny(u8, line, " ");

        // Part Two
        while (token_stream.next()) |word| {
            try line_list.append(try std.fmt.parseInt(i16, word, 10));
        }

        // Iter through
        escape_for: for (0..line_list.items.len) |i| {
            safe = false;
            const start_index: usize = if (i == 0) 1 else 0;

            var previous: i16 = line_list.items[start_index];
            var line_order: Order = .unknown;

            for ((start_index + 1)..line_list.items.len) |j| {
                if (i == j) continue;

                const current: i16 = line_list.items[j];

                const difference: i16 = current - previous;
                if (@abs(difference) == 0 or @abs(difference) > 3) continue :escape_for;

                switch (line_order) {
                    .unknown => {
                        line_order = if (difference > 0) Order.ascending else Order.descending;
                    },
                    .ascending => if (difference < 0) continue :escape_for,
                    .descending => if (difference > 0) continue :escape_for,
                }
                previous = current;
            }
            safe = true;
            break;
        }

        if (safe) safe_lines2 += 1;

        // Part One
        var previous = line_list.items[0];
        var line_order: Order = .unknown;

        for (line_list.items[1..]) |num| {
            const current: i16 = num;

            const difference: i16 = current - previous;
            if (@abs(difference) == 0 or @abs(difference) > 3) continue :main_while;

            switch (line_order) {
                .unknown => {
                    line_order = if (difference > 0) Order.ascending else Order.descending;
                },
                .ascending => if (difference < 0) continue :main_while,
                .descending => if (difference > 0) continue :main_while,
            }
            previous = current;
        }

        if (safe) safe_lines1 += 1;
    }

    std.debug.print("Part One: {d}\n", .{safe_lines1});
    std.debug.print("Part Two: {d}\n", .{safe_lines2});
}
