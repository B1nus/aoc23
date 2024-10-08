const std = @import("std");

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    var sum: usize = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var i: usize = 0;
        var max = [_]usize{0} ** 3;
        while (i < line.len and line[i] != ':') : (i += 1) {}

        var num: usize = 0;
        while (i < line.len) switch (line[i]) {
            '0'...'9' => {
                num *= 10;
                num += line[i] - 48;
                i += 1;
            },
            'r' => {
                max[0] = @max(max[0], num);
                num = 0;
                i += 4;
            },
            'g' => {
                max[1] = @max(max[1], num);
                num = 0;
                i += 6;
            },
            'b' => {
                max[2] = @max(max[2], num);
                num = 0;
                i += 5;
            },
            else => i += 1,
        };
        const power: usize = max[0] * max[1] * max[2];
        sum += power;
    }

    std.debug.print("Day " ++ day ++ " >> {d}\n", .{sum});
}
