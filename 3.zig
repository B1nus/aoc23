const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");

    // try stdout.print("{s}", .{input});
    var sum: usize = 0;
    const width = @as(isize, @intCast(find_width(input)));
    // try stdout.print("{d}", .{width});
    var i: usize = 0;

    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            '0'...'9' => if (search_symbol(input, i, width)) {
                const number = search_number(input, i);
                const value = try std.fmt.parseInt(usize, input[number.start..number.end], 10);
                sum += value;
                i = number.end;
                // try stdout.print("[{d}..{d}] = {} i={d}; ", .{ number.start, number.end, value, i });
            },
            else => {},
        }
    }

    try stdout.print("Day " ++ day ++ " -> {d}\n", .{sum});
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
