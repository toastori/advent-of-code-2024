const std = @import("std");

const EMPTY: comptime_int = std.math.maxInt(usize);

fn sum_mul(value: usize, num_count: usize, count: usize) usize {
    const off_count = num_count + count;
    return if (@import("builtin").mode == .Debug) blk: {
        break :blk value * ((off_count * (off_count - 1) / 2) - (count * (count -| 1) / 2));
    } else value * ((off_count * (off_count - 1) / 2) - (count * (count - 1) / 2));
}

const combo = struct {
    value: usize,
    count: usize,
};

fn calc_checksum(source: *const std.ArrayList(combo)) !usize {
    var result: usize = 0;

    var read_backward = try source.clone();
    defer read_backward.deinit();

    var count: usize = 0;

    for (source.items, 0..) |num, i| {
        if (i >= read_backward.items.len - 1) break;
        if (num.value != EMPTY) {
            result += sum_mul(num.value, num.count, count);
            count += num.count;
            continue;
        }

        var empty_count = num.count;
        while (empty_count != 0 and i < read_backward.items.len - 1) {
            if (read_backward.getLast().value == std.math.maxInt(usize)) {
                _ = read_backward.pop();
                continue;
            }
            const last = read_backward.getLast();
            if (last.count > empty_count) {
                result += sum_mul(last.value, empty_count, count);

                read_backward.items[read_backward.items.len - 1].count -= empty_count;
                count += empty_count;
                break;
            } else {
                result += sum_mul(last.value, last.count, count);

                _ = read_backward.pop();
                count += last.count;
                empty_count -= last.count;
            }
        }
    }

    if (read_backward.getLast().count != source.items[read_backward.items.len - 1].count and read_backward.getLast().value != std.math.maxInt(usize)) {
        const last = read_backward.getLast();
        result += last.value * (((last.count + count) * (last.count + count - 1) / 2) - (count * (count - 1) / 2));
    }

    return result;
}

fn defragment(source: *std.ArrayList(combo)) !void {
    var back_index: usize = source.items.len - 1;

    while (back_index > 1) : (back_index -= 1) {
        if (source.items[back_index].value == EMPTY) continue;
        const last = source.items[back_index];
        var front_index: usize = 1;
        while (front_index < back_index) : (front_index += 1) {
            if (source.items[front_index].value != EMPTY or // Not space
                source.items[front_index].count < last.count // Not fit
            ) continue;

            if (last.count == source.items[front_index].count) { // Space same width as file
                source.items[front_index] = last;
            } else { // Space bigger than file
                source.items[front_index].count -= last.count;
                back_index += 1;
                try source.insert(front_index, last);
            }

            if (back_index == source.items.len - 1) { // Is last item
                _ = source.pop();
                while (source.getLast().value == EMPTY) {
                    _ = source.pop();
                }
                back_index = source.items.len;
            } else {
                source.items[back_index].value = EMPTY;

                const back = source.items[back_index + 1]; // Merge back empty
                if (back.value == EMPTY) {
                    source.items[back_index] = .{ .value = EMPTY, .count = last.count + back.count };
                    _ = source.orderedRemove(back_index + 1);
                }
                const front = source.items[back_index - 1]; // Merge front empty
                if (front.value == EMPTY) {
                    source.items[back_index - 1].count += source.items[back_index].count;
                    _ = source.orderedRemove(back_index);
                }
            }

            break;
        }
    }
}

pub fn day9(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var sequence = try std.ArrayList(combo).initCapacity(allocator, 20000);

    var mem_block: usize = 0;
    while (true) : (mem_block += 1) { // Read
        const byte = try fin.readByte(); // Make file
        if (byte == '\n') break;
        const count: usize = @intCast(byte - '0');
        sequence.appendAssumeCapacity(.{ .value = mem_block, .count = count });

        const empty_byte = try fin.readByte(); // Make empty
        if (empty_byte != '\n') {
            if (empty_byte == '0') continue;
            const empty_count: usize = @intCast(empty_byte - '0');
            sequence.appendAssumeCapacity(.{ .value = std.math.maxInt(usize), .count = empty_count });
        } else break;
    }

    if (sequence.getLast().value == EMPTY) _ = sequence.pop();

    const sum1 = try calc_checksum(&sequence);

    try defragment(&sequence);

    var sum2: usize = 0;
    var count: usize = 0;

    for (sequence.items) |num| {
        defer count += num.count;
        if (num.value == EMPTY) continue;
        sum2 += sum_mul(num.value, num.count, count);
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
