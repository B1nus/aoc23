const std = @import("std");

// So, the pattern is a large diamons shape. The idea is to Emulate steps to account
// for the corners and edges and keep track of how many filled grids there are.
pub fn main() !void {
    const steps = try std.fmt.parseInt(usize, (try std.process.argsAlloc(std.heap.page_allocator))[1], 10);
    var grid = try Grid.parse_grid(@embedFile("21.txt"));

    // I don't need to do all parts separetly. I can just do one big step simulation and
    // Then pick out ranges and multiply them to get the answer.
    //
    // Hmm, how big does it have to be?
    if (steps > grid.width * 3) {
        _ = try grid.take_steps(.{ grid.width >> 1, grid.height >> 1 }, 10);
        std.debug.print("{d} spots", .{grid.plots.count()});
    } else {
        _ = try grid.take_steps(.{ grid.width >> 1, grid.height >> 1 }, steps);
        std.debug.print("{d} spots", .{grid.plots.count()});
    }
}

const Grid = struct {
    chars: []const u8,
    width: isize,
    height: isize,
    plots: std.AutoHashMap([2]isize, void),

    pub fn parse_grid(input: []const u8) !@This() {
        var lines = std.mem.splitScalar(u8, input, '\n');
        const width: isize = @intCast(lines.peek().?.len);
        const height: isize = @divFloor(@as(isize, @intCast(input.len + 1)), (width + 1));
        var grid = try std.heap.page_allocator.alloc(u8, @intCast(width * height));
        var i: usize = 0;
        while (lines.next()) |line| {
            std.mem.copyForwards(u8, grid[i..], line);
            i += @intCast(width);
        }
        return @This(){
            .chars = grid,
            .width = width,
            .height = height,
            .plots = std.AutoHashMap([2]isize, void).init(std.heap.page_allocator),
        };
    }

    pub fn count(self: Grid, min_x: isize, max_x: isize, min_y: isize, max_y: isize) usize {
        var it = self.plots.keyIterator();
        var count: usize = 0;
        while (it.next()) |i| {
            if (i.*[0] <= max_x and i.*[0] >= min_x and i.*[])
        }
    }

    // Take steps and return the count of plots
    pub fn take_steps(self: *Grid, start: [2]isize, steps: usize) !u128 {
        self.plots.clearAndFree();
        try self.plots.put(start, void{});
        for (0..steps) |_| {
            var new_plots = std.AutoHashMap([2]isize, void).init(std.heap.page_allocator);
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

    pub fn get_char(self: *Grid, x: isize, y: isize) u8 {
        return self.chars[@intCast(@mod(x, self.width) + @mod(y, self.height) * self.width)];
    }

    pub fn is_plot(self: Grid, x: isize, y: isize) bool {
        return self.plots.get(.{ x, y }) != null;
    }

    pub fn print(self: *Grid, label: []const u8, size: usize) void {
        std.debug.print("\x1b[1m{s}:\x1b[0m\n", .{label});
        for (0..size * @as(usize, @intCast(self.height))) |ty| {
            for (0..size * @as(usize, @intCast(self.width))) |tx| {
                const x = @as(isize, @intCast(tx)) - self.width * (@as(isize, @intCast(size)) >> 1);
                const y = @as(isize, @intCast(ty)) - self.height * (@as(isize, @intCast(size)) >> 1);
                if (x == self.width >> 1 or y == self.height >> 1) {
                    std.debug.print("\x1b[31m", .{});
                }
                if (self.is_plot(x, y)) {
                    std.debug.print("O", .{});
                } else {
                    std.debug.print("{c}", .{self.get_char(x, y)});
                }
                std.debug.print("\x1b[0m", .{});
            }
            std.debug.print("\n", .{});
        }
    }
};

const Point = struct {
    x: isize,
    y: isize,
};

pub fn arithmetic_sum(start: usize, step: usize, amount: usize) usize {
    return amount * (start + (step * (amount - 1)) / 2);
}
