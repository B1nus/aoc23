const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..2];
    const input = @embedFile(day ++ ".txt");
    const allocator = std.heap.page_allocator;

    const grid = try Grid.from_input(input, allocator);
    grid.find_loop();
    grid.find_open();
    const enclosed_area = grid.find_enclosed();
    grid.print_grid();

    print("Day " ++ day ++ " >> {d}\n", .{enclosed_area});
}

const Grid = struct {
    tiles: []Tile,
    start: usize,
    width: usize,
    height: usize,

    pub fn from_input(input: []const u8, allocator: std.mem.Allocator) !Grid {
        const width = std.mem.indexOfScalar(u8, input, '\n').?;
        const height = (input.len + 1) / (width + 1);

        var tiles = try allocator.alloc(Tile, width * height);
        var i: usize = 0;
        var start: usize = undefined;
        for (input) |c| {
            switch (c) {
                '\n' => {},
                else => {
                    tiles[i] = Tile{ .unknown = c };
                    if (c == 'S') start = i;
                    i += 1;
                },
            }
        }

        return Grid{
            .tiles = tiles,
            .start = start,
            .width = width,
            .height = height,
        };
    }

    pub fn find_loop(self: Grid) void {
        // Find starting pipe.
        const next = for (0..4) |dir| {
            const mask_: u4 = 0b0001;
            const mask = mask_ << @intCast(dir);
            const index = self.get_adjacent_index(self.start, mask).?;
            if (!self.is_char(index, '.')) break index;
        } else unreachable;
        var turtle = Turtle.from_diff(self.start, next);
        self.to_loop(turtle.pos);

        while (turtle.pos != self.start) {
            turtle.move(self.tiles[turtle.pos], self.width);
            self.to_loop(turtle.pos);
        }
    }

    pub fn find_enclosed(self: Grid) usize {
        var enclosed_area: usize = 0;
        for (self.tiles) |*t| {
            switch (t.*) {
                .loop => {},
                .squeeze => {},
                .outside => {},
                .unknown => {
                    t.* = Tile.inside;
                    enclosed_area += 1;
                },
                else => unreachable,
            }
        }
        return enclosed_area;
    }

    pub fn find_open(self: Grid) void {
        for (self.tiles) |*t| {
            switch (t.*) {
                .loop => {},
                else => t.* = Tile.junk,
            }
        }

        for (0..@max(self.width, self.height)) |_| {
            for (0..self.width * self.height) |i| {
                self.collapse_tile(i);
            }
        }
    }

    pub fn squeezable(self: Grid, index: usize, from_side: u4) bool {
        return switch (self.tiles[index]) {
            Tile.squeeze => |f| return f & from_side > 0,
            else => false,
        };
    }

    pub fn collapse_tile(self: Grid, index: usize) void {
        switch (self.tiles[index]) {
            .junk => if (self.adjacent(index, up) == Tile.outside or
                self.adjacent(index, left) == Tile.outside or
                self.adjacent(index, down) == Tile.outside or
                self.adjacent(index, right) == Tile.outside or
                self.squeezable(self.get_adjacent_index(index, right).?, left) or
                self.squeezable(self.get_adjacent_index(index, down).?, up) or
                self.squeezable(self.get_adjacent_index(index, up).?, down) or
                self.squeezable(self.get_adjacent_index(index, left).?, right))
            {
                self.tiles[index] = Tile.outside;
            },
            .loop => {
                // Going up
                if (self.adjacent(index, down) == Tile.outside or self.squeezable(self.get_adjacent_index(index, down).?, left)) {
                    return switch (self.tiles[index]) {
                        .loop => |c| switch (c) {
                            '|' => self.tiles[index] = Tile{ .squeeze = left },
                            '7' => self.tiles[index] = Tile{ .squeeze = left ^ down },
                            'L' => self.tiles[index] = Tile{ .squeeze = left ^ down },
                            'F' => self.tiles[index] = Tile{ .squeeze = left ^ up },
                            else => {},
                        },
                        else => {},
                    };
                }
                // Goind left
                if (self.adjacent(index, right) == Tile.outside or self.squeezable(self.get_adjacent_index(index, right).?, down)) {
                    return switch (self.tiles[index]) {
                        .loop => |c| switch (c) {
                            '-' => self.tiles[index] = Tile{ .squeeze = down },
                            'J' => self.tiles[index] = Tile{ .squeeze = down ^ right },
                            'L' => self.tiles[index] = Tile{ .squeeze = down ^ left },
                            'F' => self.tiles[index] = Tile{ .squeeze = down ^ right },
                            else => {},
                        },
                        else => {},
                    };
                }
                // Goind down
                if (self.adjacent(index, up) == Tile.outside or self.squeezable(self.get_adjacent_index(index, up).?, right)) {
                    return switch (self.tiles[index]) {
                        .loop => |c| switch (c) {
                            '|' => self.tiles[index] = Tile{ .squeeze = right },
                            '7' => self.tiles[index] = Tile{ .squeeze = right ^ up },
                            'J' => self.tiles[index] = Tile{ .squeeze = right ^ down },
                            'L' => self.tiles[index] = Tile{ .squeeze = right ^ up },
                            else => {},
                        },
                        else => {},
                    };
                }
                // Going right
                if (self.adjacent(index, left) == Tile.outside or self.squeezable(self.get_adjacent_index(index, left).?, up)) {
                    return switch (self.tiles[index]) {
                        .loop => |c| switch (c) {
                            '-' => self.tiles[index] = Tile{ .squeeze = up },
                            'F' => self.tiles[index] = Tile{ .squeeze = up ^ left },
                            '7' => self.tiles[index] = Tile{ .squeeze = up ^ right },
                            'J' => self.tiles[index] = Tile{ .squeeze = up ^ left },
                            else => {},
                        },
                        else => {},
                    };
                }
            },
            else => {},
        }
    }

    pub fn is_char(self: Grid, index: usize, char: u8) bool {
        return switch (self.tiles[index]) {
            .unknown => |c| return c == char,
            else => return false,
        };
    }

    pub fn to_loop(self: Grid, index: usize) void {
        self.tiles[index] = switch (self.tiles[index]) {
            .unknown => |c| Tile{ .loop = c },
            .loop => self.tiles[index],
            else => unreachable,
        };
    }

    pub fn print_grid(self: Grid) void {
        for (self.tiles, 0..) |t, i| {
            switch (t) {
                Tile.unknown => |c| print("{c}", .{c}),
                Tile.loop => |c| print("\x1b[1m{c}\x1b[0m", .{c}),
                Tile.junk => print(" ", .{}),
                Tile.outside => print("\x1b[31mO\x1b[0m", .{}),
                Tile.inside => print("\x1b[32mI\x1b[0m", .{}),
                Tile.squeeze => |m| print("\x1b[33m{c}\x1b[0m", .{if (m < 10) @as(u8, @intCast(m)) + '0' else @as(u8, @intCast(m)) - 10 + 'A'}),
            }
            if ((i + 1) % self.width == 0) print("\n", .{});
        }
    }

    pub fn adjacent(self: Grid, index: usize, mask: u4) Tile {
        if (self.get_adjacent_index(index, mask)) |i| {
            return self.tiles[i];
        } else {
            return Tile.outside;
        }
    }

    pub fn get_adjacent_index(self: Grid, index: usize, mask: u4) ?usize {
        return switch (mask) {
            up => if (index < self.width) null else index - self.width,
            left => if (index % self.width == 0) null else index - 1,
            down => if (index + self.width >= self.tiles.len) null else index + self.width,
            right => if (index % self.width == self.width - 1) null else index + 1,
            up ^ right => if (index < self.width or index % self.width == self.width - 1) null else index - self.width + 1,
            up ^ left => if (index < self.width or index % self.width == 0) null else index - self.width - 1,
            down ^ right => if (index + self.width >= self.tiles.len or index % self.width == self.width - 1) null else index + self.width + 1,
            down ^ left => if (index + self.width >= self.tiles.len or index % self.width == 0) null else index + self.width - 1,
            else => unreachable,
        };
    }
};

const Tile = union(enum) {
    unknown: u8,
    junk,
    loop: u8,
    squeeze: u4, // The bits are in order of wasd. The second most significant bit is for left squeeze for example.
    inside,
    outside,
};

const up: u4 = 0b1000;
const left: u4 = 0b0100;
const down: u4 = 0b0010;
const right: u4 = 0b0001;

const Turtle = struct {
    pos: usize,
    mov: Movement,

    pub fn from_diff(start: usize, cur: usize) Turtle {
        const movement = Movement.from_diff(start, cur);
        const pos = cur;

        return Turtle{
            .pos = pos,
            .mov = movement,
        };
    }

    pub fn move(turtle: *Turtle, tile: Tile, width: usize) void {
        const pipe = switch (tile) {
            .loop => |c| c,
            else => unreachable,
        };

        turtle.mov = find_move(pipe, turtle.mov);
        const diff = turtle.mov.to_diff(width);
        turtle.pos = @intCast(@as(isize, @intCast(turtle.pos)) + diff);
    }
};

const Movement = enum {
    Up,
    Down,
    Left,
    Right,

    pub fn from_diff(start: usize, cur: usize) Movement {
        var diff: isize = @intCast(cur);
        diff -= @intCast(start);

        return switch (diff) {
            1 => Movement.Right,
            -1 => Movement.Left,
            else => if (diff > 0) Movement.Down else Movement.Up,
        };
    }

    pub fn to_diff(movement: Movement, width: usize) isize {
        return switch (movement) {
            Movement.Up => -@as(isize, @intCast(width)),
            Movement.Down => @intCast(width),
            Movement.Right => 1,
            Movement.Left => -1,
        };
    }
};

pub fn find_move(pipe: u8, previous: Movement) Movement {
    return switch (pipe) {
        '|' => previous,
        '-' => previous,
        'L' => if (previous == Movement.Down) Movement.Right else Movement.Up,
        'J' => if (previous == Movement.Down) Movement.Left else Movement.Up,
        '7' => if (previous == Movement.Up) Movement.Left else Movement.Down,
        'F' => if (previous == Movement.Up) Movement.Right else Movement.Down,
        else => unreachable,
    };
}
