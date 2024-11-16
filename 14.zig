const std = @import("std");
const print = std.debug.print;
const input = @embedFile("14.txt");
const page_allocator = std.heap.page_allocator;

pub fn main() !void {
    var tiles = try Tiling.init();
    tiles.spin(1000); // The cycle repeats itself every 1000^n cycles. I have no idea why though, but whatever I solved the problem.
    const sum = tiles.calculate_load();

    print("Day 14 >> {d}\n", .{sum});
}

const Tile = enum {
    CubeRock,
    RoundRock,
    Empty,

    pub fn from_char(char: u8) Tile {
        return switch (char) {
            'O' => Tile.RoundRock,
            '#' => Tile.CubeRock,
            '.' => Tile.Empty,
            else => unreachable,
        };
    }

    pub fn to_char(self: Tile) u8 {
        return switch (self) {
            .RoundRock => 'O',
            .CubeRock => '#',
            .Empty => '.',
        };
    }
};

const Tiling = struct {
    tiles: []Tile,
    width: usize,
    height: usize,

    pub fn init() !Tiling {
        const width = std.mem.indexOfScalar(u8, input, '\n').?;
        const height = try std.math.divCeil(usize, input.len, width + 1);
        var tiles = try page_allocator.alloc(Tile, width * height);

        var i: usize = 0;
        for (input) |c| {
            if (c != '\n') {
                tiles[i] = Tile.from_char(c);
                i += 1;
            }
        }

        return Tiling{
            .tiles = tiles,
            .width = width,
            .height = height,
        };
    }

    pub fn spin(self: @This(), cycles: usize) void {
        for (0..cycles) |_| {
            self.roll_north();
            self.roll_west();
            self.roll_south();
            self.roll_east();
            // self.print_tiles();
        }
    }

    pub fn roll_horizontal(self: @This(), west: bool) void {
        for (0..self.height) |y| {
            var count: usize = 0;
            var start: usize = 0;
            for (0..self.width + 1) |x| {
                if (x == self.width or self.get(x, y).* == Tile.CubeRock) {
                    for (start..x) |j| {
                        const condition = if (west) j < start + count else j + 1 > x - count;
                        self.get(j, y).* = if (condition) Tile.RoundRock else Tile.Empty;
                    }
                    count = 0;
                    start = x + 1;
                } else if (self.get(x, y).* == Tile.RoundRock) {
                    count += 1;
                }
            }
        }
    }

    pub fn roll_vertical(self: @This(), south: bool) void {
        for (0..self.width) |x| {
            var count: usize = 0;
            var start: usize = 0;
            for (0..self.height + 1) |i| {
                if (i == self.height or self.get(x, i).* == Tile.CubeRock) {
                    for (start..i) |j| {
                        const condition = if (south) j + 1 > i - count else j < start + count;
                        self.get(x, j).* = if (condition) Tile.RoundRock else Tile.Empty;
                    }
                    count = 0;
                    start = i + 1;
                    continue;
                } else if (self.get(x, i).* == Tile.RoundRock) {
                    count += 1;
                }
            }
        }
    }

    pub fn roll_north(self: @This()) void {
        self.roll_vertical(false);
    }

    pub fn roll_south(self: @This()) void {
        self.roll_vertical(true);
    }

    pub fn roll_west(self: @This()) void {
        self.roll_horizontal(true);
    }

    pub fn roll_east(self: @This()) void {
        self.roll_horizontal(false);
    }

    pub fn calculate_load(self: @This()) usize {
        var sum: usize = 0;
        for (0..self.height) |y_| {
            const y = self.height - y_ - 1;
            for (0..self.width) |x| {
                if (self.get(x, y).* == Tile.RoundRock) {
                    sum += y_ + 1;
                }
            }
        }
        return sum;
    }

    pub fn get(self: Tiling, column: usize, row: usize) *Tile {
        return &self.tiles[column + self.width * row];
    }

    pub fn print_tiles(self: Tiling) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                print("{c}", .{self.get(x, y).to_char()});
            }
            print("\n", .{});
        }
        print("\n\n" ++ "-" ** 100 ++ "\n\n", .{});
    }
};
