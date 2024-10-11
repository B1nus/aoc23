const std = @import("std");
const p = std.debug.print;
const root = std.math.sqrt;
pub fn dbg(any: anytype) void {
    p("{any}", .{any});
}

pub fn main() !void {
    const day = @src().file[0..1];
    var product: usize = 1;
    const times = [_]usize{ 48, 93, 85, 95 };
    const distances = [_]usize{ 296, 1928, 1236, 1391 };

    for (times, distances) |t, d| {
        var ways: usize = 0;
        for (1..t + 1) |x| {
            if ((t - x) * x > d) {
                ways += 1;
            }
        }
        product *= ways;
    }

    p("Day " ++ day ++ " -> {d}\n", .{product});
}
