const std = @import("std");
const input = @embedFile("21.txt");

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
    var lines = std.mem.splitScalar(u8, input, '\n');
    const width = lines.peek().?.len;
    const height = (input.len + 1) / (width + 1);
    var grid = try std.heap.page_allocator.alloc(u8, width * height);
    var i: usize = 0;
    while (lines.next()) |line| {
        std.mem.copyForwards(u8, grid[i..], line);
        i += width;
    }

    const uneven = try step(grid, width, width / 2 + height / 2 * width, 131, false);
    const even = try step(grid, width, width / 2 + height / 2 * width, 132, false);

    // Uneven grids = 10231221350 * 4
    // Even grids = 10231322500 * 4
    const grid_sum: u128 = (1023122135 * uneven + 10231322500 * even) * 4 + uneven; // Adding one because of the starting grid

    var tiny_edge_sum: u128 = 0;
    tiny_edge_sum += try step(grid, width, grid.len - width, 64, true); // north east
    tiny_edge_sum += try step(grid, width, grid.len - 1, 64, true); // north west
    tiny_edge_sum += try step(grid, width, width - 1, 64, true); // south west
    tiny_edge_sum += try step(grid, width, 0, 64, true); // south east
    tiny_edge_sum *= 202300;

    var edge_sum: u128 = 0;
    edge_sum += try step(grid, width, grid.len - width, 65 * 3, true); // north east
    edge_sum += try step(grid, width, grid.len - 1, 65 * 3, true); // north west
    edge_sum += try step(grid, width, width - 1, 65 * 3, true); // south west
    edge_sum += try step(grid, width, 0, 65 * 3, true); // south east
    edge_sum *= 202299;

    var corner_sum: u128 = 0;
    corner_sum += try step(grid, width, grid.len - width / 2 - 1, 130, true); // north
    corner_sum += try step(grid, width, height / 2 * width + width - 1, 130, true); // west
    corner_sum += try step(grid, width, width / 2, 130, true); // south
    corner_sum += try step(grid, width, height / 2 * width, 130, true); // east

    const result = grid_sum + tiny_edge_sum + edge_sum + corner_sum;
    std.debug.print("Day 21 >> {d}\n", .{result});
}

pub fn step(grid: []const u8, width: usize, start: usize, steps: usize, print: bool) !u128 {
    var plots = std.AutoHashMap(usize, void).init(std.heap.page_allocator);
    try plots.put(start, void{});
    for (0..steps) |_| {
        var new_plots = std.AutoHashMap(usize, void).init(std.heap.page_allocator);
        defer new_plots.deinit();
        var plots_iter = plots.keyIterator();
        while (plots_iter.next()) |plot| {
            if (plot.* % width != 0 and grid[plot.* - 1] != '#') try new_plots.put(plot.* - 1, void{});
            if (plot.* % width != width - 1 and grid[plot.* + 1] != '#') try new_plots.put(plot.* + 1, void{});
            if (plot.* + width < grid.len and grid[plot.* + width] != '#') try new_plots.put(plot.* + width, void{});
            if (plot.* >= width and grid[plot.* - width] != '#') try new_plots.put(plot.* - width, void{});
        }
        plots.clearAndFree();
        plots = try new_plots.clone();
    }
    if (print) {
        print_map(grid, width, &plots);
        std.debug.print("\n\n", .{});
    }
    return @intCast(plots.count());
}

pub fn print_map(grid: []const u8, width: usize, plots: *const std.AutoHashMap(usize, void)) void {
    for (0..grid.len / width) |y| {
        for (0..width) |x| {
            if (x == width / 2 or y == grid.len / width / 2) {
                std.debug.print("\x1b[31m", .{});
            }
            if (plots.get(x + y * width) != null) {
                std.debug.print("O", .{});
            } else {
                std.debug.print("{c}", .{grid[x + y * width]});
            }
            std.debug.print("\x1b[0m", .{});
        }
        std.debug.print("\n", .{});
    }
}
