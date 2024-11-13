// Try every combination (using for example grey code or binary counting)
// For every combination, check if it's valid
// Print the sum
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..2];
    const input = @embedFile(day ++ ".txt");
    const allocator = std.heap.page_allocator;

    var sum: usize = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var line_i: usize = 0;
    while (lines.next()) |line_| {
        if (line_.len > 0) {
            const line_list = try unfold(line_, allocator, 5);
            defer line_list.deinit();
            const line = line_list.items;
            // Parse line
            var parts = std.mem.splitScalar(u8, line, ' ');
            const damaged = parts.next().?;
            var group_strings = std.mem.splitScalar(u8, parts.next().?, ',');
            var groups = std.ArrayList(usize).init(allocator);
            while (group_strings.next()) |group_string| {
                if (group_string.len > 0) {
                    try groups.append(try std.fmt.parseInt(usize, group_string, 10));
                }
            }

            for (0..try std.math.powi(usize, 2, std.mem.count(u8, damaged, "?"))) |broken| {
                if (correct(damaged, broken, groups.items)) {
                    // print_attempt(damaged, broken);
                    sum += 1;
                }
            }
            print("line:{d} out of 1000, sum:{d}\n", .{ line_i, sum });
            line_i += 1;
        }
    }

    print("Day " ++ day ++ " >> {d}\n", .{sum});
}

pub fn unfold(line: []const u8, allocator: std.mem.Allocator, repeat: usize) !std.ArrayList(u8) {
    var unfolded = std.ArrayList(u8).init(allocator);
    var parts = std.mem.splitScalar(u8, line, ' ');
    const symbols = parts.next().?;
    const groups = parts.next().?;

    for (0..repeat) |i| {
        try unfolded.appendSlice(symbols);
        if (i != repeat - 1) {
            try unfolded.append('?');
        }
    }
    try unfolded.append(' ');

    for (0..repeat) |i| {
        try unfolded.appendSlice(groups);
        if (i != repeat - 1) {
            try unfolded.append(',');
        }
    }
    return unfolded;
}

// Debugging
pub fn print_attempt(damaged: []const u8, broken: u64) void {
    var unknown_i: usize = 0;
    for (damaged) |c| {
        switch (c) {
            '?' => {
                if (bitAsBool(broken, @intCast(unknown_i))) print("#", .{}) else print(".", .{});
                unknown_i += 1;
            },
            else => print("{c}", .{c}),
        }
    }
    print("\n", .{});
}

pub fn correct(damaged: []const u8, broken: u64, groups: []const usize) bool {
    var i: usize = 0;
    var broken_i: usize = 0;
    for (groups) |group| {
        if (i >= damaged.len) {
            return false;
        }
        var count: usize = 0;
        while (i < damaged.len) {
            switch (damaged[i]) {
                '.' => {
                    if (count > 0) {
                        break;
                    }
                },
                '#' => {
                    count += 1;
                },
                '?' => {
                    if (bitAsBool(broken, @intCast(broken_i))) {
                        count += 1;
                    } else if (count > 0) {
                        break;
                    }
                    broken_i += 1;
                },
                else => unreachable,
            }
            i += 1;
        }
        if (count != group) {
            return false;
        }
    }

    while (i < damaged.len) {
        switch (damaged[i]) {
            '#' => return false,
            '?' => {
                if (bitAsBool(broken, @intCast(broken_i))) {
                    return false;
                }
                broken_i += 1;
            },
            else => {},
        }
        i += 1;
    }

    return std.mem.count(u8, damaged[i..], "#") == 0;
}

fn bitAsBool(x: usize, index: u6) bool {
    return (x >> index) & 0x1 == 1;
}

const expect = std.testing.expect;

test "correct" {
    try expect(correct("???.###", 0b101, &.{ 1, 1, 3 }));
    try expect(correct(".??..??...?##.", 0b10101, &.{ 1, 1, 3 }));
    try expect(!correct("#?#", 0b1, &.{ 1, 1 }));
    try expect(!correct("?###????????", 0b0, &.{ 3, 2, 1 }));
}

test "unfold" {
    const unfolded = try unfold(".# 1", std.testing.allocator, 5);
    defer unfolded.deinit();
    try expect(std.mem.eql(u8, ".#?.#?.#?.#?.# 1,1,1,1,1", unfolded.items));
}
