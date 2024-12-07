# Day 7 (especially part 2)

When dealing with contatination, the first idea is to concat the numbers in string
```zig
result = std.fmt.parseInt(u64, std.fmt.format(&buf, "{d}{d}", .{result, num}) catch unreachable, 10) catch unreachable;
```
the result is 693.1ms...700.7ms\
\
Then to do in a mathematical way
```zig
result = result * (10 * std.mant.pow(u64, 10, @intFromFloat(@log10(@as(f32, @floatFromInt(num)))))) + num;
```
The code looks pretty messy, but the performance goes to 428.4ms...433.0ms\
\
Until this point, my part1 and part2 runs in the same function, just add to part1's sum when the calculation don't have concat involved.\
Running part1 before part2 to eliminate possibility needed to run part2 reduce the time down to 381.7ms...383.7ms\
\
But logarithm is such an expensive operation, since `u64` is too big for the inputs, why not just store the digits in high bits of the number?
```zig
while (tokenizer.next()) |word| : (nums_count += 1) {
    nums[nums_count] = try std.fmt.parseInt(u64, word, 10);
    // I just chose a random number (58)
    nums[nums_count] += @intCast(words.len << 58);
}
```
Then just shift the bits down to get the digits
```zig
result = result * std.math.pow(u64, 10, num >> 58) + (num & std.math.maxInt(u32));
```
And just mask the numbers for extracting values
```zig
result += num & std.math.maxInt(u32);
```
We somehow don;t need to cast the `maxInt(u32)` because it returns comptime_int, good!\
It reduced runtime down to 260.0ms...264.0ms, but we can still do better\
\
`u64` is still too big, we can store even more things inside to reduce repetitive processes, why not just store the 10^n directly?
```zig
while (tokenizer.next()) |word| : (nums_count += 1) {
    nums[nums_count] = try std.fmt.parseInt(u64, word, 10);
    // Use u32 this time because it feels better
    // (same digits count as the actual value)
    nums[nums_count] += std.math.pow(u64, 10, @intCast(word.len)) << 32;
}
```
Concatination is now replaced as:
```zig
result = result * (num >> 32) + (num & std.math.maxInt(32));
```
The code looks very clean now, and the most important thing, performance\
It now runs 203.8ms...212.0ms, more than 3x the speed of the original code!\
\
It shows that, the big O is not that important for performance. (x\
\
\
* Times are measured with hyperfine on a R7-7700X
