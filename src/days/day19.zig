const std = @import("std");

const CharTree = struct {
    /// storing index of next char in array
    /// `0` as terminator index
    const CharNode = struct {
        black: u16 = 0,
        blue: u16 = 0,
        green: u16 = 0,
        red: u16 = 0,
        white: u16 = 0,
        termination: u16 = 1,

        fn hasTermination(self: @This()) bool {
            return self.termination == 0;
        }

        fn assignFor(self: *@This(), c: u8, value: u16) void {
            switch (c) {
                'b' => self.black = value,
                'u' => self.blue = value,
                'g' => self.green = value,
                'r' => self.red = value,
                else => self.white = value,
            }
        }

        fn valueOf(self: @This(), c: u8) u16 {
            return switch (c) {
                'b' => self.black,
                'u' => self.blue,
                'g' => self.green,
                'r' => self.red,
                else => self.white,
            };
        }

        fn valueOfIsNull(self: @This(), c: u8) bool {
            return self.valueOf(c) == 0;
        }
    };

    tree: std.ArrayList(CharNode),

    fn initCapacity(allocator: std.mem.Allocator, num: usize) !@This() {
        var result = try std.ArrayList(CharNode).initCapacity(allocator, 6 + num);
        result.appendAssumeCapacity(.{ .black = 0, .blue = 1, .green = 2, .red = 3, .white = 4 });
        inline for (0..5) |_| {
            result.appendAssumeCapacity(CharNode{});
        }
        return .{
            .tree = result,
        };
    }

    fn getHead(self: @This()) CharNode {
        return self.tree.items[0];
    }
    fn getNode(self: @This(), node: CharNode, c: u8) CharNode {
        return self.tree.items[node.valueOf(c)];
    }

    fn addString(self: *@This(), str: []const u8) !void {
        var idx: usize = 0;
        for (str) |c| {
            const val = self.tree.items[idx].valueOf(c);
            if (val == 0) {
                try self.tree.append(CharNode{});
                self.tree.items[idx].assignFor(c, @intCast(self.tree.items.len - 1));
                idx = self.tree.items.len - 1;
            } else {
                idx = val;
            }
        }
        self.tree.items[idx].termination = 0;
    }
};

pub fn day19(allocator: std.mem.Allocator, fin: *const std.io.AnyReader) !void {
    var unlimited = try CharTree.initCapacity(allocator, 64);
    {
        var fin_buffer: [3000]u8 = undefined;
        if (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
            var tok = std.mem.tokenizeAny(u8, line, ", ");
            while (tok.next()) |word| {
                try unlimited.addString(word);
            }
        } else return;
        try fin.skipUntilDelimiterOrEof('\n');
    }

    var sum1: u32 = 0;
    var sum2: usize = 0;

    var fin_buffer: [128]u8 = undefined;
    while (try fin.readUntilDelimiterOrEof(&fin_buffer, '\n')) |line| {
        var add1 = false;
        var counts = [_]usize{1} ++ ([_]usize{0} ** 63);
        var indicator: std.bit_set.IntegerBitSet(64) = std.bit_set.IntegerBitSet(64).initEmpty();
        indicator.set(0);

        for (0..line.len) |i| {
            if (!indicator.isSet(i)) continue;
            const substr = line[i..];

            var node = unlimited.getHead();
            for (substr, 0..) |c, checked| {
                if (node.valueOfIsNull(c)) break;
                node = unlimited.getNode(node, c);

                if (!node.hasTermination()) continue;
                if (checked != substr.len - 1) { // not end of string
                    counts[i + checked + 1] += counts[i];
                    indicator.set(i + checked + 1);
                    continue;
                }

                // end of string
                if (indicator.isSet(i)) sum2 += counts[i];
                indicator.unset(i);
                add1 = true;
            }
        }
        if (add1) sum1 += 1;
    }

    std.debug.print("Part One: {d}\n", .{sum1});
    std.debug.print("Part Two: {d}\n", .{sum2});
}
