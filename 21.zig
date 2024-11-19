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
// Large edges, There are 202299 per direction and they can be simulated by stepping 131 + 65 times
// from the corresponding corner.
//
// You have to simulate one of these for each direction since they have different obstacles to depending
// on the direction.
//
// So,
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

    var sum: usize = 0;
    for (0..width * height) |j| {
        if (j % 2 == 0 and grid[j] != '#') {
            sum += 1;
        }
    }

    std.debug.print("Day 21 >> {d}\n", .{width});
}
