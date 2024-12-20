const std = @import("std");

pub fn main() !void {
    const steps = 26501365;
    var grid = try Grid.parse_grid(@embedFile("21.txt"), std.heap.page_allocator);
    const count = try grid.count_reach(steps);
    std.debug.print("Day 21 >> {d}\n", .{count});

    // Explanation:
    //
    // I'm simulating the steps modulo the width of the grid plus 3 times the width.
    // This means that I get a diamond with the correct edge pieces but way smaller.
    // Then I did some math to find out how many times each grid is repeated in the real
    // amount of steps. Took me some time to work it out on paper, It's a fun exercise
    // to derive the general formula which also works with the example data.
    //
    // Great puzzle Eric Wastl!
}

const Point = struct {
    x: isize,
    y: isize,

    pub fn in_range(self: @This(), min_x: isize, max_x: isize, min_y: isize, max_y: isize) bool {
        return self.x >= min_x and self.x <= max_x and self.y >= min_y and self.y <= max_y;
    }

    pub fn new(x: isize, y: isize) @This() {
        return @This(){ .x = x, .y = y };
    }
};

const Set = struct {
    hash: std.AutoHashMap(Point, void),
    later: std.ArrayList(Point),

    pub fn new(allocator: std.mem.Allocator) @This() {
        return @This(){ .hash = std.AutoHashMap(Point, void).init(allocator), .later = std.ArrayList(Point).init(allocator) };
    }

    pub fn has(self: @This(), point: Point) bool {
        return self.hash.get(point) != null;
    }

    pub fn put(self: *@This(), item: Point) !void {
        try self.hash.put(item, void{});
    }

    pub fn delay_put(self: *@This(), item: Point) !void {
        try self.later.append(item);
    }

    pub fn clear(self: *@This()) void {
        self.hash.clearAndFree();
    }

    pub fn apply(self: *@This()) !void {
        while (self.later.popOrNull()) |p| {
            try self.put(p);
        }
        self.later.clearAndFree();
    }

    pub fn iterator(self: @This()) std.AutoHashMap(Point, void).KeyIterator {
        return self.hash.keyIterator();
    }
};

const Grid = struct {
    chars: []const u8,
    size: usize,
    radius: usize,
    reach: Set,

    pub fn parse_grid(input: []const u8, allocator: std.mem.Allocator) !@This() {
        var lines = std.mem.splitScalar(u8, input, '\n');
        const size = lines.peek().?.len;
        var grid = try allocator.alloc(u8, size * size);
        var i: usize = 0;
        while (lines.next()) |line| {
            std.mem.copyForwards(u8, grid[i..], line);
            i += size;
        }
        return @This(){
            .chars = grid,
            .size = size,
            .radius = size / 2,
            .reach = Set.new(allocator),
        };
    }

    pub fn count_reach(self: *Grid, steps: usize) !u128 {
        if (steps > 3 * self.size) {
            const s = steps % self.size + 3 * self.size;
            const m = steps / self.size - 3;
            const o = m * (m + 4);
            const c = m * (m + 2);

            try self.take_steps(Point.new(0, 0), s);
            var count: u128 = self.reach.hash.count();
            count += m * self.count_reach_in_grid(Point.new(1, -1));
            count += m * self.count_reach_in_grid(Point.new(2, -1));
            count += m * self.count_reach_in_grid(Point.new(3, -1));
            count += m * self.count_reach_in_grid(Point.new(1, 1));
            count += m * self.count_reach_in_grid(Point.new(2, 1));
            count += m * self.count_reach_in_grid(Point.new(3, 1));
            count += m * self.count_reach_in_grid(Point.new(-1, -1));
            count += m * self.count_reach_in_grid(Point.new(-2, -1));
            count += m * self.count_reach_in_grid(Point.new(-3, -1));
            count += m * self.count_reach_in_grid(Point.new(-1, 1));
            count += m * self.count_reach_in_grid(Point.new(-2, 1));
            count += m * self.count_reach_in_grid(Point.new(-3, 1));
            count += c * self.count_reach_in_grid(Point.new(0, 0));
            count += o * self.count_reach_in_grid(Point.new(1, 0));

            return count;
        } else {
            return self.naive_count(steps);
        }
    }

    pub fn naive_count(self: *Grid, steps: usize) !u128 {
        try self.take_steps(Point.new(0, 0), steps);
        return @intCast(self.reach.hash.count());
    }

    pub fn count_reach_in_grid(self: Grid, grid: Point) usize {
        var it = self.reach.iterator();
        var count: usize = 0;
        while (it.next()) |p| {
            if (self.in_range(p.*, grid)) count += 1;
        }
        return count;
    }

    // Take steps and return the count of plots
    pub fn take_steps(self: *Grid, start: Point, steps: usize) !void {
        try self.reach.put(start);
        for (0..steps) |_| {
            var reach_iter = self.reach.iterator();
            while (reach_iter.next()) |reach| {
                const x, const y = .{ reach.x, reach.y };
                if (self.get_char(x - 1, y) != '#') try self.reach.delay_put(Point.new(x - 1, y));
                if (self.get_char(x + 1, y) != '#') try self.reach.delay_put(Point.new(x + 1, y));
                if (self.get_char(x, y + 1) != '#') try self.reach.delay_put(Point.new(x, y + 1));
                if (self.get_char(x, y - 1) != '#') try self.reach.delay_put(Point.new(x, y - 1));
            }
            self.reach.clear();
            try self.reach.apply();
        }
    }

    pub fn reset(self: *Grid) void {
        self.reach.clear();
    }

    pub fn get_char(self: *Grid, x: isize, y: isize) u8 {
        const size: isize = @intCast(self.size);
        const size_half: isize = @intCast(self.size / 2);
        return self.chars[@intCast(@mod(x + size_half, size) + @mod(y + size_half, size) * size)];
    }

    pub fn is_plot(self: Grid, point: Point) bool {
        return self.reach.has(point);
    }

    pub fn in_range(self: Grid, point: Point, grid_pos: Point) bool {
        const size: isize = @intCast(self.size);
        const radius: isize = @intCast(self.radius);
        return point.in_range(grid_pos.x * size - radius, grid_pos.x * size + radius, grid_pos.y * size - radius, grid_pos.y * size + radius);
    }

    pub fn print(self: *Grid, label: []const u8, size: usize) void {
        std.debug.print("\x1b[1m{s}:\x1b[0m\n", .{label});
        const offset: isize = @intCast(size * self.size / 2);
        for (0..size * self.size) |y_| {
            for (0..size * self.size) |x_| {
                const x = @as(isize, @intCast(x_)) - offset;
                const y = @as(isize, @intCast(y_)) - offset;
                const point = Point.new(x, y);
                if (x == 0 or y == 0) {
                    std.debug.print("\x1b[31m", .{});
                } else if (x_ % self.size == 0 or x_ % self.size == self.size - 1 or y_ % self.size == 0 or y_ % self.size == self.size - 1) {
                    std.debug.print("\x1b[32m", .{});
                }
                if (self.is_plot(point)) {
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

pub fn arithmetic_sum(start: usize, step: usize, amount: usize) usize {
    return amount * (start + (step * (amount - 1)) / 2);
}
