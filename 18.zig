const std = @import("std");

pub fn main() !void {
    // Welp, I cheated again. Sorry: https://www.youtube.com/watch?v=bGWK76_e-LM&t=250s
    //
    // I'm using the shoelace theorem and Rick's theorem. I did however find a slight
    // optimisation in the shoelace theorem for our data. I skip every other vertex, I figured
    // it out by working it out on paper. I probably wouldn't have discovered the shoelace theorem
    // myself, but it is quite easy to understand if you look at the pictures from wikipedia.
    const allocator = std.heap.page_allocator;
    var x = std.ArrayList(isize).init(allocator);
    var y = std.ArrayList(isize).init(allocator);
    try x.append(0);
    try y.append(0);

    // Counting boundary points for pick's theorem later.
    var b: usize = 1;
    var lines = std.mem.splitScalar(u8, @embedFile("18.txt"), '\n');
    while (lines.next()) |line| {
        if (line.len > 0) {
            const color_i = std.mem.indexOfScalar(u8, line, '#').? + 1;
            const color = line[color_i .. line.len - 1];
            const direction = color[5];
            const steps = try std.fmt.parseInt(usize, color[0..5], 16);

            var dx: isize = 0;
            var dy: isize = 0;
            switch (direction) {
                '3' => dy = -1,
                '2' => dx = -1,
                '1' => dy = 1,
                '0' => dx = 1,
                else => unreachable,
            }

            b += steps;

            try x.append(x.getLast() + dx * @as(isize, @intCast(steps)));
            try y.append(y.getLast() + dy * @as(isize, @intCast(steps)));
        }
    }

    // Shoelace Theorem
    const n: usize = x.items.len;
    var A_: isize = 0;
    for (0..n / 2) |i_| {
        const i = i_ * 2; // Index every other vertex. (This is my optimisation)
        const dy = y.items[(i + n - 1) % n] - y.items[(i + 1) % n];
        A_ += dy * x.items[i];
    }
    const A = @as(usize, @abs(A_)); // Don't divide by halv, this is because of my optimisation.

    const i = A + b / 2 + 1;

    std.debug.print("Day 18 >> {d}\n", .{i});
}
