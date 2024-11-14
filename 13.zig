const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const input = @embedFile("13.txt");
    var map_iter = MapIterator.new(input);

    var sum: usize = 0;
    var map_ = map_iter.next();
    var map_count: usize = 0;
    map_iterator: while (map_ != null) : ({
        map_ = map_iter.next();
        map_count += 1;
    }) {
        var map = map_.?;
        const ignore_row = map.horizontal_reflection(0);
        const ignore_col = map.vertical_reflection(0);
        for (0..map.width) |x| {
            for (0..map.height) |y| {
                map.flip_bit(y, x);
                const points = map.reflection_points(ignore_row, ignore_col);
                if (points > 0) {
                    sum += points;
                    continue :map_iterator;
                }
                map.flip_bit(y, x);
            }
        }
    }

    print("Day 13 >> {d}\n", .{sum});
}

const Map = struct {
    characters: [30]usize,
    width: usize,
    height: usize,

    pub fn flip_bit(self: *Map, row: usize, column: usize) void {
        const mask: usize = 1;
        self.characters[row] ^= (mask << @intCast(self.width - 1)) >> @intCast(column);
    }

    pub fn is_rock(self: Map, row: usize, column: usize) bool {
        return ((self.characters[row] << @intCast(column + 1)) >> @intCast(self.width)) & 1 == 1;
    }

    pub fn print_map(self: Map) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (self.is_rock(y, x)) {
                    print("#", .{});
                } else {
                    print(".", .{});
                }
            }
            print("\n", .{});
        }
    }

    pub fn horizontal_reflection(self: Map, ignore: usize) usize {
        outer: for (1..self.height) |y| {
            if (y != ignore) {
                for (0..@min(y, self.height - y)) |d| {
                    if (self.characters[y + d] != self.characters[y - d - 1]) {
                        continue :outer;
                    }
                }
                return y;
            }
        }
        return 0;
    }

    pub fn vertical_reflection(self: Map, ignore: usize) usize {
        outer: for (1..self.width) |x| {
            if (x != ignore) {
                for (0..@min(x, self.width - x)) |d| {
                    for (0..self.height) |y| {
                        if (self.is_rock(y, x + d) != self.is_rock(y, x - d - 1)) {
                            continue :outer;
                        }
                    }
                }
                return x;
            }
        }
        return 0;
    }

    pub fn reflection_points(self: Map, row_ignore: usize, col_ignore: usize) usize {
        return self.horizontal_reflection(row_ignore) * 100 + self.vertical_reflection(col_ignore);
    }
};

const MapIterator = struct {
    lines: std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar),
    fn new(input: []const u8) MapIterator {
        const lines = std.mem.splitScalar(u8, input, '\n');
        return MapIterator{
            .lines = lines,
        };
    }

    fn next(self: *MapIterator) ?Map {
        var characters = [_]usize{undefined} ** 30;
        var width: usize = undefined;
        var height: usize = 0;

        while (self.lines.next()) |line| {
            if (line.len == 0) {
                break;
            } else {
                if (height == 0) {
                    width = line.len;
                }
                var row: usize = 0;
                for (line) |c| {
                    row = row << 1;
                    switch (c) {
                        '#' => row ^= 0b1,
                        '.' => {},
                        else => unreachable,
                    }
                }
                characters[height] = row;
                height += 1;
            }
        }

        if (height == 0) {
            return null;
        } else {
            return Map{
                .characters = characters,
                .width = width,
                .height = height,
            };
        }
    }
};

const expect = std.testing.expect;

test "iteration" {
    const input =
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
        \\
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
    ;

    var map_iter = MapIterator.new(input);
    const map1 = map_iter.next().?;
    const map2 = map_iter.next().?;
    try expect(map_iter.next() == null);
    try expect(map1.width == 9);
    try expect(map1.height == 7);
    try expect(map2.width == 9);
    try expect(map2.height == 7);
    try expect(map1.characters[0] == 0b101100110);
    try expect(map1.characters[4] == 0b001011010);
    try expect(map1.characters[6] == 0b101011010);
    try expect(map2.characters[0] == 0b100011001);
    try expect(map2.characters[6] == 0b100001001);
}

test "reflections1" {
    const input =
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
    ;
    var map_iter = MapIterator.new(input);
    const map = map_iter.next().?;
    try expect(map_iter.next() == null);
    try expect(map.horizontal_reflection() == 0);
    try expect(map.vertical_reflection() == 5);
    try expect(map.reflection_points() == 5);
}

test "reflections2" {
    const input =
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
    ;

    var map_iter = MapIterator.new(input);
    const map = map_iter.next().?;
    try expect(map_iter.next() == null);
    try expect(map.horizontal_reflection() == 4);
    try expect(map.vertical_reflection() == 0);
    try expect(map.reflection_points() == 400);
}

test "reflections3" {
    const input =
        \\###.###.#.#
        \\...##......
        \\..#########
        \\###.#......
        \\##....#####
        \\......#..##
        \\###....#...
        \\...##....##
        \\##...#..###
    ;

    var map_iter = MapIterator.new(input);
    const map = map_iter.next().?;
    try expect(map_iter.next() == null);
    try expect(map.horizontal_reflection() == 0);
    try expect(map.vertical_reflection() == 1);
    try expect(map.reflection_points() == 1);
}

test "reflections4" {
    const input =
        \\.....########..
        \\####...####...#
        \\####...####...#
        \\.#...########..
        \\#.##..##..##..#
        \\##.....####....
        \\...###..##..###
    ;

    var map_iter = MapIterator.new(input);
    const map = map_iter.next().?;
    try expect(map_iter.next() == null);
    try expect(map.horizontal_reflection() == 0);
    try expect(map.vertical_reflection() == 9);
    try expect(map.reflection_points() == 9);
}

test "reflection top" {
    const input =
        \\####...####...#
        \\####...####...#
        \\.#...########..
        \\#.##..##..##..#
        \\##.....####....
        \\...###.###..###
    ;

    var map_iter = MapIterator.new(input);
    const map = map_iter.next().?;
    try expect(map_iter.next() == null);
    try expect(map.horizontal_reflection() == 1);
    try expect(map.vertical_reflection() == 0);
    try expect(map.reflection_points() == 100);
}

test "reflection bottom" {
    const input =
        \\.#.
        \\###
        \\###
    ;

    var map_iter = MapIterator.new(input);
    const map = map_iter.next().?;
    try expect(map_iter.next() == null);
    try expect(map.horizontal_reflection() == 2);
    try expect(map.vertical_reflection() == 0);
    try expect(map.reflection_points() == 200);
}

test "reflection end" {
    const input =
        \\.#..
        \\.###
        \\####
    ;

    var map_iter = MapIterator.new(input);
    const map = map_iter.next().?;
    try expect(map_iter.next() == null);
    try expect(map.horizontal_reflection() == 0);
    try expect(map.vertical_reflection() == 3);
    try expect(map.reflection_points() == 3);
}
