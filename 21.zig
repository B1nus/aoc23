const std = @import("std");
const input = @embedFile("21.txt");

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

    var plots = std.AutoHashMap(usize, void).init(std.heap.page_allocator);
    try plots.put(std.mem.indexOfScalar(u8, grid, 'S').?, void{});
    for (0..64) |_| {
        var new_plots = std.AutoHashMap(usize, void).init(std.heap.page_allocator);
        defer new_plots.deinit();
        var plots_iter = plots.keyIterator();
        while (plots_iter.next()) |plot| {
            if (grid[plot.* - 1] != '#') try new_plots.put(plot.* - 1, void{});
            if (grid[plot.* + 1] != '#') try new_plots.put(plot.* + 1, void{});
            if (grid[plot.* + width] != '#') try new_plots.put(plot.* + width, void{});
            if (grid[plot.* - width] != '#') try new_plots.put(plot.* - width, void{});
        }
        plots.clearAndFree();
        plots = try new_plots.clone();
    }
    print_map(grid, width, &plots);

    std.debug.print("Day 21 >> {d}\n", .{plots.count()});
}

pub fn print_map(grid: []const u8, width: usize, plots: *std.AutoHashMap(usize, void)) void {
    for (0..grid.len / width) |y| {
        for (0..width) |x| {
            if (plots.get(x + y * width) != null) {
                std.debug.print("O", .{});
            } else {
                std.debug.print("{c}", .{grid[x + y * width]});
            }
        }
        std.debug.print("\n", .{});
    }
}
