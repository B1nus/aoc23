const std = @import("std");
pub fn main() void {
    var strings = std.mem.splitScalar(u8, @embedFile("15.txt"), ',');
    var sum: usize = 0;
    while (strings.next()) |string| {
        var val: usize = 0;
        for (string) |c| {
            if (c != '\n') {
                val += c;
                val *= 17;
                val = val % 256;
            }
        }
        sum += val;
    }
    std.debug.print("Day 15 >> {d}\n", .{sum});
}
