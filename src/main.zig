const std = @import("std");
const builtin = @import("builtin");
const days = @import("days.zig");

fn invalidArg() void {
    std.debug.print("Invalid args\nusage: exe day filename\n", .{});
    std.process.exit(1);
}

fn invalidFile(filename: []const u8) void {
    std.debug.print("Invalid filename: file {s} not found\n", .{filename});
    std.process.exit(1);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var args = if (builtin.os.tag != .windows) std.process.args() else try std.process.argsWithAllocator(allocator);

    // Skip Executable
    _ = args.next();

    // Parse Args
    const day: u8 = if (args.next()) |arg| std.fmt.parseInt(u8, arg, 10) catch 0 else 0;
    const filename: []const u8 = if (args.next()) |arg| arg else "";
    // Handle wrong Args
    if (day == 0 or filename.len == 0) {
        invalidArg();
        unreachable;
    }

    // Reader
    const file = std.fs.cwd().openFile(filename, .{}) catch {
        invalidFile(filename);
        unreachable;
    };
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const fin = buffered_reader.reader();

    switch (day) {
        1 => try days.day1(allocator, &fin.any()),
        2 => try days.day2(allocator, &fin.any()),
        3 => try days.day3(&fin.any()),
        4 => try days.day4(&fin.any(), &file),
        5 => try days.day5(&fin.any()),
        6 => try days.day6(allocator, &fin.any()),
        7 => try days.day7(&fin.any()),
        8 => try days.day8(allocator, &fin.any()),
        9 => try days.day9(allocator, &fin.any()),
        10 => try days.day10(allocator, &fin.any()),
        11 => try days.day11(allocator, &fin.any()),
        12 => try days.day12(allocator, &fin.any()),
        13 => try days.day13(&fin.any()),
        14 => try days.day14(allocator, &fin.any()),
        15 => try days.day15(allocator, &fin.any()),
        16 => try days.day16(allocator, &fin.any()),
        else => std.debug.print("Day{d} not available\n", .{day}),
    }
}
