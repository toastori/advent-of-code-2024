const std = @import("std");

var reg_a: usize = undefined;
var reg_b: usize = undefined;
var reg_c: usize = undefined;

fn valueOf(opr: u8) usize {
    return switch (opr) {
        4 => reg_a,
        5 => reg_b,
        6 => reg_c,
        else => @intCast(opr),
    };
}

fn run(prog: []u8, output: *std.ArrayList(u8)) !void { // return last jump
    var ptr: usize = 0;
    while (ptr != prog.len) {
        const ins = prog[ptr];
        const opr = prog[ptr + 1];

        switch (ins) {
            0 => reg_a >>= @intCast(valueOf(opr)),
            1 => reg_b ^= valueOf(opr),
            2 => reg_b = valueOf(opr) & 0b111,
            3 => {
                if (reg_a != 0) {
                    ptr = valueOf(opr);
                    continue;
                }
            },
            4 => reg_b ^= reg_c,
            5 => {
                const o_value: u8 = @intCast(valueOf(opr) % 8);
                try output.append(o_value);
            },
            6 => reg_b = reg_a >> @intCast(valueOf(opr)),
            7 => reg_c = reg_a >> @intCast(valueOf(opr)),
            else => unreachable,
        }

        ptr += 2;
    }
}

pub fn day17(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var prog = std.ArrayList(u8).init(allocator);
    var output = std.ArrayList(u8).init(allocator);

    var fin_buffer: [64]u8 = undefined;
    reg_a = try std.fmt.parseInt(usize, (try fin.readUntilDelimiter(&fin_buffer, '\n'))[12..], 10);
    reg_b = try std.fmt.parseInt(usize, (try fin.readUntilDelimiter(&fin_buffer, '\n'))[12..], 10);
    reg_c = try std.fmt.parseInt(usize, (try fin.readUntilDelimiter(&fin_buffer, '\n'))[12..], 10);
    _ = try fin.readUntilDelimiter(&fin_buffer, ' ');

    while (true) {
        const byte = (fin.readByte() catch break);
        if (byte == '\n') break;
        try prog.append(byte - '0');
        _ = fin.readByte() catch break;
    }

    try run(prog.items, &output);

    std.debug.print("Part One: ", .{});
    for (output.items, 0..) |c, i| {
        std.debug.print("{d}", .{c});
        if (i < output.items.len - 1) std.debug.print(",", .{});
    }
    std.debug.print("\n", .{});

    var sum2: usize = 0;

    var possible_list: [2]std.ArrayList(usize) = undefined;
    inline for (&possible_list) |*list| {
        list.* = std.ArrayList(usize).init(allocator);
    }
    try possible_list[0].append(0);
    var possible_list_idx: usize = 0;
    main_while: while (true) {
        for (possible_list[possible_list_idx].items) |possible| {
            for (0..8) |i| {
                reg_a = possible + i;
                reg_b = 0;
                reg_c = 0;
                output.clearRetainingCapacity();
                try run(prog.items, &output);
                // some prints [reg_a :: output]
                // std.debug.print("0o{o} :: {any}\n", .{ possible + i, output.items });
                if (std.mem.eql(u8, prog.items, output.items)) {
                    sum2 = possible + i;
                    break :main_while;
                }
                if (std.mem.eql(u8, prog.items[(prog.items.len - output.items.len)..], output.items)) {
                    try possible_list[possible_list_idx ^ 1].append((possible + i) << 3);
                }
            }
        }
        possible_list[possible_list_idx].clearRetainingCapacity();
        possible_list_idx ^= 1;
    }

    std.debug.print("Part Two: {d}\n", .{sum2});
}
