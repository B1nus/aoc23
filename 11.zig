const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..2];
    const input = @embedFile(day ++ ".txt");
    const allocator = std.heap.page_allocator;

    var universe = try expand_height(input, allocator);
    var width = std.mem.indexOfScalar(u8, input, '\n').?;
    const height = universe.items.len / width;
    expand_width(&universe, width);
    width = universe.items.len / height;
    const galaxies = galaxy_indicies(universe.items, allocator);

    var sum: usize = 0;
    for (galaxies.items[0 .. galaxies.items.len - 1], 0..) |galaxy, i| {
        for (galaxies.items[i + 1 ..]) |other| {
            sum += distance(galaxy, other, width);
        }
    }

    print("Day " ++ day ++ " >> {d}\n", .{sum});
}

pub fn galaxy_indicies(universe: []const u8, allocator: std.mem.Allocator) std.ArrayList(usize) {
    var galaxies = std.ArrayList(usize).init(allocator);
    for (universe, 0..) |c, i| {
        if (c == '#') {
            galaxies.append(i) catch {};
        }
    }
    return galaxies;
}

pub fn expand_height(universe: []const u8, allocator: std.mem.Allocator) !std.ArrayList(u8) {
    var expanded = try std.ArrayList(u8).initCapacity(allocator, 100 * 1000000);
    var lines = std.mem.splitScalar(u8, universe, '\n');
    var height: usize = 0;
    var width: usize = 0;
    while (lines.next()) |line| {
        expanded.appendSlice(line) catch {};
        height += 1;
        if (std.mem.indexOfScalar(u8, line, '#') == null) {
            width = line.len;
            expanded.appendSlice(line) catch {};
            height += 1;
        }
    }
    return expanded;
}

pub fn expand_width(expanded: *std.ArrayList(u8), width: usize) void {
    const height = expanded.items.len / width;
    columns: for (0..width) |x_| {
        const x = width - x_ - 1;
        const width_ = expanded.items.len / height;
        for (0..height) |y| {
            if (expanded.items[x + y * width_] == '#') continue :columns;
        }
        for (0..height) |y_| {
            const y = height - y_ - 1;
            expanded.insert(x + y * width_, '.') catch {};
        }
    }
}

// For debugging
pub fn print_universe(universe: []const u8, width: usize, name: []const u8) void {
    const height = universe.len / width;
    print("{s}: width={d} height={d}\n", .{ name, width, height });
    for (0..height) |h| {
        for (0..width) |x| {
            print("{c}", .{universe[x + h * width]});
        }
        print("\n", .{});
    }
}

pub fn distance(index1: usize, index2: usize, width: usize) usize {
    const y1 = index1 / width;
    const x1 = index1 % width;
    const y2 = index2 / width;
    const x2 = index2 % width;

    return posDiff(x1, x2) + posDiff(y1, y2);
}

pub fn posDiff(a: usize, b: usize) usize {
    return if (a > b) a - b else b - a;
}

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

test "distance" {
    try expect(distance(2, 76, 14) == 9);
    try expect(distance(4, 23, 14) == 6);
}

test "galaxies" {
    const universe =
        \\....#........
        \\.........#...
        \\#............
        \\.............
        \\.............
        \\........#....
        \\.#...........
        \\............#
        \\.............
    ;

    const result = galaxy_indicies(universe, test_allocator);
    defer result.deinit();

    try expect(std.mem.eql(usize, result.items, &.{ 4, 23, 28, 78, 85, 110 }));
}

test "expand" {
    const universe =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;
    const expanded = "....#.................#...#..............................................#.....#.......................#...................................#...#....#.......";

    var result = try expand_height(universe, test_allocator);
    expand_width(&result, 10);
    defer result.deinit();

    try expect(std.mem.eql(u8, result.items, expanded));
}
