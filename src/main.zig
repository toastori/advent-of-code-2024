const std = @import("std");
const days = @import("days.zig");

fn invalidArg() void {
    std.debug.print("Invalid args\nusage: exe day filename\n", .{});
    std.process.exit(1);
}

fn invalidFile(filename: []const u8) void {
    std.debug.print("Invalid filename: file {s} not found\n", .{filename});
}

pub fn main() !void {
    var args = std.process.args();

    // Skip Executable
    _ = args.next();

    // Parse Args
    const day: u8 = if (args.next()) |arg| std.fmt.parseInt(u8, arg, 10) catch 0 else 0;
    const filename: []const u8 = if (args.next()) |arg| arg else "";
    // Handle wrong Args
    if (day == 0 or filename.len == 0) {
        invalidArg();
        std.process.exit(1);
    }

    // Reader
    const file = std.fs.cwd().openFile(filename, .{}) catch {
        invalidFile(filename);
        unreachable;
    };
    defer file.close();
    const file_reader = file.reader();
    var buffered_reader = std.io.bufferedReader(file_reader);
    const fin = buffered_reader.reader();

    switch (day) {
        1 => try days.day1(&fin.any()),
        2 => try days.day2(&fin.any()),
        3 => try days.day3(&fin.any()),
        4 => try days.day4(&fin.any(), &file_reader.context),
        5 => try days.day5(&fin.any()),
        else => std.debug.print("Day{d} not available\n", .{day}),
    }
}
