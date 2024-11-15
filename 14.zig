const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const input = @embedFile("14.txt");
    const width = std.mem.indexOfScalar(u8, input, '\n').? + 1;

    const allocator = std.heap.page_allocator;
    var tiling = try allocator.alloc(u8, input.len);
    defer allocator.free(tiling);
    std.mem.copyForwards(u8, tiling, input);
    for (0..(input.len + 1) / width) |_| {
        for (1..input.len + 1) |i_| {
            const i = input.len - i_;
            if (tiling[i] == 'O' and i > width and tiling[i - width] == '.') {
                tiling[i] = '.';
                tiling[i - width] = 'O';
            }
        }
    }

    var sum: usize = 0;
    for (tiling, 0..) |t, i| {
        const height = (input.len + 1) / width - (i + 1) / width;
        if (t == 'O') {
            sum += height;
        }
    }
    print("Day 14 >> {d}\n", .{sum});
}
