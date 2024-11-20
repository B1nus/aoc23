const std = @import("std");

// Even number of steps is this patterns
//
// .O.O.O.
// O.O.O.O
// .O.O.O.
// O.O.O.O
// .O.O.O.
//
// Uneven number of steps is this pattern
//
// O.O.O.O
// .O.O.O.
// O.O.O.O
// .O.O.O.
// O.O.O.O

// I have a possible solution, but it's going to get quite messy.

// So, the shape is a diamond
//
// ...O...
// ..O.O..
// .O.O.O.
// O.O.O.O
// .O.O.O.
// ..O.O..
// ...O...
//
// But with a width and height of 26501365 * 2 + 1
//
// The center is not filled, because we are on an uneven step count.
//
// 26501365 / 131 = 202300. So we reach out 202300 grids in all four directions.
// The diamond has a for way rotational symmetry. The amount of "uneven" is the
// arithmetic sum of 1 + 3 + ... + 202299. The map of "uneven" O and "even" X grids
// is illustrated:
//
// X
// OX
// XOX
// OXOX
// XOXOX
// OXOXOX
// XOXOXOX
// OXOXOXOX
//
// The two outer most diagonals are not complete grids, I will deal with them in a second.
// It follows that the amount of even grid are 2 + 4 + ... + 202298. This is only a quarter
// of the diamond so we multiply by four and get:
// Uneven grids = 10231221350 * 4
// Even grids = 10231322500 * 4

// So, about the corners and edges. They are the exact same everywhere, except for the fact
// that they are on different parts of the grid, meaning that they will have different counts.
//
// What follows must be repeated for each direction:
//
// The corner looks like this:
//
// .....O.....
// ....O.O....
// ...O.O.O...
// ..O.O.O.O..
// .O.O.O.O.O.
// O.O.O.O.O.O
// .O.O.O.O.O.
// O.O.O.O.O.O
// .O.O.O.O.O.
// O.O.O.O.O.O
// .O.O.O.O.O.
//
// This can be simulated by starting at the bottom and stepping 65*2 times. Do this for each
// direction and you've got this in the bag.
//
// We have two more parts to take care of:
//
// Tiny edges   and     Large Edges
// ...........          .O.O.O.....
// ...........          O.O.O.O....
// ...........          .O.O.O.O...
// ...........          O.O.O.O.O..
// ...........          .O.O.O.O.O.
// ...........          O.O.O.O.O.O
// ...........          .O.O.O.O.O.
// O..........          O.O.O.O.O.O
// .O.........          .O.O.O.O.O.
// O.O........          O.O.O.O.O.O
// .O.O.......          .O.O.O.O.O.
// O.O.O......          O.O.O.O.O.O
//
// Tiny edges, There are 202300 per direction and they can be simulated by stepping 64 times
// from the corresponding corner.
//
// Large edges, There are 202299 per direction and they can be simulated by stepping 65 * 2 + 65 times
// from the corresponding corner.
//
// You have to simulate one of these for each direction since they have different obstacles to depending
// on the direction.
pub fn main() !void {
    var grid = try Grid.parse_grid(@embedFile("21.txt"));

    const s = 50;
    const w = grid.width;
    const r = (w - 1) / 2; // The amount of steps from the start to the edge
    const g_steps = ceil_div(s - r, w);
    const c_steps1 = (s - r - 1) % w;
    const c_steps2 = (s - r - 1) % w + w;
    // const e_steps1 = c_steps1 - r - 1;
    // const e_steps2 = c_steps2 - r - 1;
    // const e_steps3 = c_steps2 + w - r - 1;
    // const e_count1 = g_steps;
    // const e_count2 = g_steps - 1;
    // const e_count3 = g_steps - 2;
    const A_steps = (s % 2) + w + 101;
    const B_steps = (s % 2) + w + 100;
    const A_rows = @divFloor(g_steps, 2) - 1;
    const B_rows = @divFloor(g_steps - 1, 2);
    const A_count = arithmetic_sum(2, 2, A_rows);
    const B_count = arithmetic_sum(1, 2, B_rows);

    const A_tiles = try grid.take_steps(.{ w / 2, w / 2 }, A_steps);
    const B_tiles = try grid.take_steps(.{ w / 2, w / 2 }, B_steps);
    const r_corner1_tiles = try grid.take_steps(.{ 0, w / 2 }, c_steps1);
    grid.print("c1");
    const r_corner2_tiles = try grid.take_steps(.{ 0, w / 2 }, c_steps2);
    grid.print("c2");
    const r_corner_tiles = r_corner1_tiles + r_corner2_tiles;

    var result: u128 = 0;
    result += (A_tiles * A_count + B_tiles * B_count) * 4;
    result += A_tiles; // The middle grid
    result += r_corner_tiles; // + u_corner_tiles + l_corner_tiles + d_corner_tiles;
}

const Grid = struct {
    chars: []const u8,
    width: usize,
    height: usize,
    plots: std.AutoHashMap([2]usize, void),
    size: usize,

    pub fn parse_grid(input: []const u8) !@This() {
        var lines = std.mem.splitScalar(u8, input, '\n');
        const width = lines.peek().?.len;
        const height = (input.len + 1) / (width + 1);
        var grid = try std.heap.page_allocator.alloc(u8, width * height);
        var i: usize = 0;
        while (lines.next()) |line| {
            std.mem.copyForwards(u8, grid[i..], line);
            i += width;
        }
        return @This(){
            .chars = grid,
            .width = width,
            .height = height,
            .plots = std.AutoHashMap([2]usize, void).init(std.heap.page_allocator),
        };
    }

    // Take steps and return the count of plots
    pub fn take_steps(self: *Grid, start: [2]usize, steps: usize) !u128 {
        self.plots.clearAndFree();
        try self.plots.put(start, void{});
        for (0..steps) |_| {
            var new_plots = std.AutoHashMap([2]usize, void).init(std.heap.page_allocator);
            defer new_plots.deinit();
            var plots_iter = self.plots.keyIterator();
            while (plots_iter.next()) |plot| {
                const x, const y = plot.*;
                if (self.get_char(x - 1, y) != '#') try new_plots.put(.{ x - 1, y }, void{});
                if (self.get_char(x + 1, y) != '#') try new_plots.put(.{ x + 1, y }, void{});
                if (self.get_char(x, y + 1) != '#') try new_plots.put(.{ x, y + 1 }, void{});
                if (self.get_char(x, y - 1) != '#') try new_plots.put(.{ x, y - 1 }, void{});
            }
            self.plots.clearAndFree();
            self.plots = try new_plots.clone();
        }
        return @intCast(self.plots.count());
    }

    pub fn get_char(self: *Grid, x: usize, y: usize) u8 {
        return self.chars[x % (self.width) + (y % self.height) * self.width];
    }

    pub fn is_plot(self: Grid, x: usize, y: usize) bool {
        return self.plots.get(.{ x, y }) != null;
    }

    pub fn print(self: Grid, label: []const u8) void {
        std.debug.print("\x1b[1m{s}:\x1b[0m\n", .{label});
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (x == self.width / 2 or y == self.height / 2) {
                    std.debug.print("\x1b[31m", .{});
                }
                if (self.is_plot(x, y)) {
                    std.debug.print("O", .{});
                } else {
                    std.debug.print("{c}", .{self.chars[x + y * self.width]});
                }
                std.debug.print("\x1b[0m", .{});
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn arithmetic_sum(start: usize, step: usize, amount: usize) usize {
    return amount * (start + (step * (amount - 1)) / 2);
}

pub fn ceil_div(dividend: usize, divisor: usize) usize {
    return @divFloor(dividend + divisor - 1, divisor);
}
