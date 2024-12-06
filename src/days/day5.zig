const std = @import("std");

fn pageToIndex(page: u8) usize {
    return @as(usize, @intCast(page)) - 10;
}

pub fn day5(fin: *const std.io.AnyReader) !void {
    var fin_buffer: [128]u8 = undefined;

    var sum1: u32 = 0;
    var sum2: u32 = 0;

    var bit_set_array: [90]std.bit_set.ArrayBitSet(u32, 91) = .{std.bit_set.ArrayBitSet(u32, 91).initEmpty()} ** 90;
    for (0..bit_set_array.len) |i| {
        bit_set_array[i].set(90); // Set page 100 to be highest priority
    }

    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| { // Rules
        if (line.len == 0) break; // End Rules reading if line.len == 0 (separator)

        const left = try std.fmt.parseInt(u8, line[0..2], 10);
        const right = try std.fmt.parseInt(u8, line[3..], 10);
        bit_set_array[pageToIndex(right)].set(pageToIndex(left)); // Set Left is before Right
    }

    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| { // Pages
        if (line.len == 0) std.debug.print("0\n", .{});
        var tokenizer = std.mem.tokenizeAny(u8, line, ",");

        var number_array: [32]u8 = undefined;
        number_array[0] = 100;
        var number_array_len: usize = 1; // Array Len (+1 for header)

        var is_correct = true;

        while (tokenizer.next()) |word| : (number_array_len += 1) {
            number_array[number_array_len] = try std.fmt.parseInt(u8, word, 10);
        }

        for (1..number_array_len) |i| {
            if (bit_set_array[pageToIndex(number_array[i])].isSet(pageToIndex(number_array[i - 1]))) { // If Previous is before Current in Rule
                continue;
            }

            // Rules obeyed
            is_correct = false;

            var sort_i = i;
            while (blk: { // Sorting
                std.mem.swap(u8, &number_array[sort_i - 1], &number_array[sort_i]); // Swap with one before
                sort_i -= 1;
                const sort_i_u8: u8 = @intCast(sort_i);
                break :blk !bit_set_array[pageToIndex(number_array[sort_i_u8])].isSet(pageToIndex(number_array[sort_i_u8 - 1])); // Is in order then break
            }) {}
        }

        if (is_correct) {
            sum1 += number_array[number_array_len / 2];
        } else {
            sum2 += number_array[number_array_len / 2];
        }
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
