const std = @import("std");

// So, the pattern is a large diamons shape. The idea is to Emulate steps to account
// for the corners and edges and keep track of how many filled grids there are.
pub fn main() !void {
    const mod_size = 7;
    const steps, const size = try parse_args(std.os.argv);
    var grid = try Grid.parse_grid(@embedFile("21.txt"), std.heap.page_allocator);

    // I don't need to do all parts separetly. I can just do one big step simulation and
    // Then pick out ranges and multiply them to get the answer.
    //
    // Hmm, how big does it have to be?
    // if (steps > grid.size * 3 - grid.radius) {
    if (steps > (mod_size / 2 - 1) * grid.size + grid.radius) {
        const modulo_steps = (steps - grid.radius - 1) % size + grid.radius + size * (mod_size / 2) + 1;
        try grid.take_steps(Point.new(0, 0), steps);
        std.debug.print("{d}, ", .{grid.reach.hash.count()});
        grid.print("normal", size);
        grid.reset();
        try grid.take_steps(Point.new(0, 0), modulo_steps);
        std.debug.print("{d}, ", .{grid.reach.hash.count()});
        grid.print("modulo", size);
    } else {
        try grid.take_steps(Point.new(0, 0), steps);
        std.debug.print("{d}\n", .{grid.reach.hash.count()});
    }
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

    pub fn count_reach(self: Grid, min_x: isize, max_x: isize, min_y: isize, max_y: isize) usize {
        var it = self.reach.iterator();
        var count: usize = 0;
        while (it.next()) |p| {
            if (p.in_range(min_x, max_x, min_y, max_y)) count += 1;
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
                }
                if (self.in_range(point, Point.new(1, 1))) {
                    std.debug.print("\x1b[35m", .{});
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

pub fn parse_args(argv: [][*:0]u8) !struct { usize, usize } {
    return .{
        try std.fmt.parseInt(usize, std.mem.span(argv[1]), 10),
        try std.fmt.parseInt(usize, std.mem.span(argv[2]), 10),
    };
}

pub fn arithmetic_sum(start: usize, step: usize, amount: usize) usize {
    return amount * (start + (step * (amount - 1)) / 2);
}
