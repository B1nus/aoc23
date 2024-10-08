const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");

    // try stdout.print("{s}", .{input});
    var sum: usize = 0;
    const width = find_width(input);
    // try stdout.print("{d}", .{width});
    var i: usize = 0;

    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            '*' => {
                var adjacent: usize = 0;
                var product: usize = 1;
                if (is_number(input, i - 1)) {
                    adjacent += 1;
                    product *= search_value(input, i - 1);
                }
                if (is_number(input, i + 1)) {
                    adjacent += 1;
                    product *= search_value(input, i + 1);
                }
                // Search top 3 spots
                var j: usize = 0;
                if (i > width) {
                    while (j <= 2) : (j += 1) {
                        if (is_number(input, i - width - 1 + j)) {
                            adjacent += 1;
                            const number = search_number(input, i - width - 1 + j);
                            j = number.end - (i - width - 1) - 1;
                            product *= parse_number(input, number);
                        }
                    }
                }
                // Search bottom 3 spots
                if (i + width < input.len) {
                    j = 0;
                    while (j <= 2) : (j += 1) {
                        if (is_number(input, i + width - 1 + j)) {
                            adjacent += 1;
                            const number = search_number(input, i + width - 1 + j);
                            j = number.end - (i + width - 1) - 1;
                            product *= parse_number(input, number);
                        }
                    }
                }

                if (adjacent == 2) {
                    sum += product;
                }
            },
            else => {},
        }
    }

    try stdout.print("Day " ++ day ++ " -> {d}\n", .{sum});
}

fn is_number(input: []const u8, index: usize) bool {
    return switch (input[index]) {
        '0'...'9' => true,
        else => false,
    };
}

fn search_symbol(input: []const u8, index: usize, width: isize) bool {
    return is_symbol(input, index, -1) or
        is_symbol(input, index, 1) or
        is_symbol(input, index, width) or
        is_symbol(input, index, width + 1) or
        is_symbol(input, index, width - 1) or
        is_symbol(input, index, -width) or
        is_symbol(input, index, -width + 1) or
        is_symbol(input, index, -width - 1);
}

fn is_symbol(input: []const u8, index: usize, offset: isize) bool {
    const i = @as(isize, @intCast(index)) + offset;
    if (i < 0 or i >= input.len) {
        return false;
    }

    return switch (input[@as(usize, @intCast(i))]) {
        '\n', '.', '0'...'9' => false,
        else => true,
    };
}

fn parse_number(input: []const u8, number: anytype) usize {
    const value = std.fmt.parseInt(usize, input[number.start..number.end], 10) catch 0;
    return value;
}

fn search_value(input: []const u8, index: usize) usize {
    const number = search_number(input, index);
    return parse_number(input, number);
}

fn search_number(input: []const u8, index: usize) struct { start: usize, end: usize } {
    var start: usize = index;
    var end: usize = index;

    while (true and start > 0) switch (input[start]) {
        '0'...'9' => start -= 1,
        else => {
            start += 1;
            break;
        },
    };

    while (true and end < input.len) switch (input[end]) {
        '0'...'9' => end += 1,
        else => break,
    };

    return .{ .start = start, .end = end };
}

fn find_width(input: []const u8) usize {
    var i: usize = 0;
    while (i < input.len and input[i] != '\n') : (i += 1) {}
    return i + 1;
}
