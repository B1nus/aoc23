const std = @import("std");
const day = "1";
const input = @embedFile(day ++ ".txt");

pub fn main() !void {
    var sum: usize = 0;
    var first = true;
    var number: ?usize = null;

    for (input, 0..) |c, i| {
        switch (c) {
            '0'...'9' => number = c - 48,
            'o' => if (check_word(input, i, "one")) {
                number = 1;
            },
            't' => if (check_word(input, i, "two")) {
                number = 2;
            } else if (check_word(input, i, "three")) {
                number = 3;
            },
            'f' => {
                if (std.mem.eql(u8, input[i .. i + 4], "four")) {
                    number = 4;
                } else if (std.mem.eql(u8, input[i .. i + 4], "five")) {
                    number = 5;
                }
            },
            's' => if (check_word(input, i, "six")) {
                number = 6;
            } else if (check_word(input, i, "seven")) {
                number = 7;
            },
            'e' => if (check_word(input, i, "eight")) {
                number = 8;
            },
            'n' => if (check_word(input, i, "nine")) {
                number = 9;
            },
            '\n' => {
                sum += number orelse 0;
                number = null;
                first = true;
            },
            else => {},
        }
        if (first and number != null) {
            sum += (number orelse 0) * 10;
            first = false;
        }
    }

    std.debug.print("Day " ++ day ++ " -> {d}\n", .{sum});
}

pub fn check_word(buffer: []const u8, index: usize, word: []const u8) bool {
    return buffer.len - index > word.len and std.mem.eql(u8, buffer[index .. index + word.len], word);
}
