const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..2];
    const input = @embedFile(day ++ ".txt");
    const allocator = std.heap.page_allocator;

    var universe = try Universe.from_text(input, allocator);
    try universe.calculate_expansions(allocator);
    const galaxies = try universe.galaxy_indicies(allocator);
    // universe.print_universe();
    const sum = universe.distance_sum(galaxies, 1000000);

    print("Day " ++ day ++ " >> {d}\n", .{sum});
}

const Universe = struct {
    universe: []const u8,
    width: usize,
    height: usize,
    expanded_rows: []usize,
    expanded_columns: []usize,

    pub fn from_text(universe_text: []const u8, allocator: std.mem.Allocator) !Universe {
        const width = std.mem.indexOfScalar(u8, universe_text, '\n').?;

        // Remove newlines
        var lines = std.mem.splitScalar(u8, universe_text, '\n');
        var universe = std.ArrayList(u8).init(allocator);
        while (lines.next()) |line| {
            if (line.len != 0) {
                try universe.appendSlice(line);
            }
        }

        return Universe{
            .universe = universe.items,
            .width = width,
            .height = universe.items.len / width,
            .expanded_rows = undefined,
            .expanded_columns = undefined,
        };
    }

    pub fn calculate_expansions(self: *Universe, allocator: std.mem.Allocator) !void {
        var expanded_rows = std.ArrayList(usize).init(allocator);
        rows: for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (self.universe[x + y * self.width] == '#') {
                    continue :rows;
                }
            }
            try expanded_rows.append(y);
        }

        var expanded_cols = std.ArrayList(usize).init(allocator);
        cols: for (0..self.width) |x| {
            for (0..self.height) |y| {
                if (self.universe[x + y * self.width] == '#') {
                    continue :cols;
                }
            }
            try expanded_cols.append(x);
        }
        self.expanded_rows = expanded_rows.items;
        self.expanded_columns = expanded_cols.items;
    }

    pub fn galaxy_indicies(self: Universe, allocator: std.mem.Allocator) ![]usize {
        var galaxies = std.ArrayList(usize).init(allocator);
        for (self.universe, 0..) |c, i| {
            if (c == '#') {
                try galaxies.append(i);
            }
        }
        return galaxies.items;
    }

    pub fn distance_sum(self: Universe, galaxies: []usize, expansion: usize) usize {
        var sum: usize = 0;
        for (galaxies[0 .. galaxies.len - 1], 0..) |galaxy, i| {
            for (galaxies[i + 1 ..]) |other| {
                sum += self.distance(galaxy, other, expansion);
            }
        }
        return sum;
    }

    pub fn distance(self: Universe, index1: usize, index2: usize, expansion: usize) usize {
        const y1 = index1 / self.width;
        const x1 = index1 % self.width;
        const y2 = index2 / self.width;
        const x2 = index2 % self.width;

        var dx = posDiff(x1, x2);
        var dy = posDiff(y1, y2);

        for (self.expanded_rows) |row_index| {
            if (row_index > @min(y1, y2) and row_index < @max(y1, y2)) {
                dy += expansion - 1;
            }
        }

        for (self.expanded_columns) |col_index| {
            if (col_index > @min(x1, x2) and col_index < @max(x1, x2)) {
                dx += expansion - 1;
            }
        }

        return dx + dy;
    }

    // For debugging
    pub fn print_universe(self: Universe) void {
        print("width={d} height={d}\n", .{ self.width, self.height });
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (std.mem.count(usize, self.expanded_rows, &.{y}) == 1) {
                    print("\x1b[31m-\x1b[0m", .{});
                } else if (std.mem.count(usize, self.expanded_columns, &.{x}) == 1) {
                    print("\x1b[31m|\x1b[0m", .{});
                } else {
                    print("{c}", .{self.universe[x + y * self.width]});
                }
            }
            print("\n", .{});
        }
    }
};

pub fn posDiff(a: usize, b: usize) usize {
    return if (a > b) a - b else b - a;
}
