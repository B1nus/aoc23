const std = @import("std");

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    var sum: usize = 0;

    var nums = [_]usize{0} ** 10;
    var copies = [_]usize{1} ** 197;
    var matches_l = [_]usize{0} ** 197;
    var left = true;
    var i: usize = 10;
    var num: usize = 0;
    var num_i: usize = 0;
    var line_i: usize = 0;
    var matches: usize = 0;

    // First pass
    while (i < input.len) {
        switch (input[i]) {
            '0'...'9' => {
                num *= 10;
                num += input[i] - 48;
                i += 1;
                switch (input[i]) {
                    '\n', ' ' => {
                        if (left) {
                            nums[num_i] = num;
                        } else {
                            // Check if num matches the winning numbers
                            for (nums) |winner| {
                                if (winner == num) {
                                    matches += 1;
                                }
                            }
                        }
                        num_i += 1;
                        num = 0;
                    },
                    else => {},
                }
            },
            '|' => {
                left = false;
                i += 2;
            },
            '\n' => {
                if (matches > 0) {
                    matches_l[line_i] = matches;
                    for (1..matches + 1) |j| {
                        const instances = copies[line_i];
                        copies[line_i + j] += instances;
                    }
                }
                sum += copies[line_i];
                matches = 0;
                left = true;
                num_i = 0;
                line_i += 1;
                i += 10;
            },
            else => {
                i += 1;
                num = 0;
            },
        }
    }

    std.debug.print("Day " ++ day ++ " >> {d}\n", .{sum});
}
