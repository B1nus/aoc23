const std = @import("std");
const stdout = std.io.getStdOut().writer();
const day = "1";
const input = @embedFile(day ++ ".txt");

pub fn main() !void {
    var sum: usize = 0;
    var number: ?usize = null;

    for (input) |c| {
        switch (c) {
            '0'...'9' => {
                if (number == null) {
                    sum += (c - 48) * 10;
                }
                number = c - 48;
            },
            '\n' => {
                sum += number orelse 0;
                number = null;
            },
            else => {},
        }
    }

    try stdout.print("Day " ++ day ++ " -> {d}\n", .{sum});
}
