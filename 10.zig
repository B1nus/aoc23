const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..2];
    const input = @embedFile(day ++ ".txt");
    const pa = std.heap.page_allocator;

    // Find width
    var lines = std.mem.splitScalar(u8, input, '\n');
    const width = lines.next().?.len + 1; // Adding one because of the newline

    const start = std.mem.indexOfScalar(u8, input, 'S').?;
    var starts = try std.ArrayList(usize).initCapacity(pa, 2);
    // I know the start is not on a edge, so I'm skipping a few checks
    if (input[start + 1] != '.') {
        try starts.append(start + 1);
    }
    if (input[start - 1] != '.') {
        try starts.append(start - 1);
    }
    if (input[start - width] != '.') {
        try starts.append(start - width);
    }
    if (input[start + width] != '.') {
        try starts.append(start + width);
    }

    // Initialize and free tiles array
    var tiles = try pa.alloc(Tile, input.len);
    defer pa.free(tiles);
    for (tiles) |*tile| {
        tile.* = Tile.Junk;
    }

    var turtle1 = Turtle.from_diff(start, starts.items[0]);
    var turtle2 = Turtle.from_diff(start, starts.items[1]);
    tiles[start] = Tile.Loop;
    tiles[turtle1.pos] = Tile.Loop;
    tiles[turtle2.pos] = Tile.Loop;
    var steps: usize = 1;

    // I assume the loop cannot be an even number of steps long. If that assumption is wrong, this can be an infinite loop.
    while (turtle1.pos != turtle2.pos) : (steps += 1) {
        turtle1.move(input[turtle1.pos], width);
        turtle2.move(input[turtle2.pos], width);
        tiles[turtle1.pos] = Tile.Loop;
        tiles[turtle2.pos] = Tile.Loop;
    }

    // Looping because I don't have the braincells to do this the smart way.
    for (0..width) |_| {
        for (0..width - 1) |x| {
            for (0..width - 1) |y| {
                collapse_tile(input, &tiles, width, x + y * width);
            }
        }
        for (0..width - 1) |x| {
            for (0..width - 1) |y| {
                collapse_tile(input, &tiles, width, x * width + y);
            }
        }
        for (0..width - 1) |x| {
            for (0..width - 1) |y| {
                collapse_tile(input, &tiles, width, x * width + width - 2 - y);
            }
        }
        for (0..width - 1) |x| {
            for (0..width - 1) |y| {
                collapse_tile(input, &tiles, width, input.len - 2 - x - y * width);
            }
        }
    }

    for (tiles) |*tile| {
        if (tile.* == Tile.Junk) {
            tile.* = Tile.Inside;
        }
    }

    for (input, tiles) |c, t| {
        if (c == '\n') {
            print("\n", .{});
        } else {
            switch (t) {
                Tile.Loop => print("\x1b[1m{c}\x1b[0m", .{c}),
                Tile.Junk => print(" ", .{}),
                Tile.Outside => print("\x1b[31mO\x1b[0m", .{}),
                Tile.Inside => print("\x1b[32mI\x1b[0m", .{}),
                else => print("\x1b[33m{c}\x1b[0m", .{c}),
            }
        }
    }

    print("Day " ++ day ++ " >> {d}\n", .{steps});
}

pub fn get_tile_val(input: []const u8, tiles: []Tile, width: usize, index: usize) Tile {
    if (tiles[index] == Tile.Junk) {
        if (index < width or
            index + width > input.len or
            index % width == 139 or
            index % width == 0 or
            tiles[index + 1] == Tile.Outside or
            tiles[index + 1 + width] == Tile.Outside or
            tiles[index + width] == Tile.Outside or
            tiles[index + width - 1] == Tile.Outside or
            tiles[index - 1] == Tile.Outside or
            tiles[index - 1 - width] == Tile.Outside or
            tiles[index - width] == Tile.Outside or
            tiles[index - width + 1] == Tile.Outside)
        {
            return Tile.Outside;
        }

        return tiles[index];
    } else if (tiles[index] == Tile.Loop) {
        if (index + width > input.len - 2 or tiles[index + width] == Tile.Outside) {
            if (index < width or input[index] == '|' or input[index])
        }
        // if ((index + width > input.len - 1 or tiles[index + width] == Tile.Outside or (tiles[index + width] == Tile.Squeeze and (input[index + width] == '|' or input[index + width] == 'L' or input[index + width] == 'F'))) and
        //     (index < width or input[index] == 'L' or input[index] == '|' or input[index] == 'F'))
        // {
        //     return Tile.Squeeze;
        // }
        //
        // if ((index < width or tiles[index - width] == Tile.Outside or (tiles[index - width] == Tile.Squeeze and (input[index - width] == '|' or input[index - width] == 'L' or input[index - width] == 'F'))) and
        //     (index + width > input.len - 1 or input[index] == 'L' or input[index] == '|' or input[index] == 'F'))
        // {
        //     return Tile.Squeeze;
        // }
        //
        // if ((index % width == 0 or tiles[index - 1] == Tile.Outside or (tiles[index - 1] == Tile.Squeeze and (input[index - 1] == '-' or input[index - 1] == 'F' or input[index - 1] == '7'))) and
        //     (index % width == 139 or input[index] == '-' or input[index] == '7' or input[index] == 'F'))
        // {
        //     return Tile.Squeeze;
        // }
        //
        // if ((index % width == 139 or tiles[index + 1] == Tile.Outside or (tiles[index + 1] == Tile.Squeeze and (input[index + 1] == '-' or input[index + 1] == 'F' or input[index + 1] == '7'))) and
        //     (index % width == 0 or input[index] == '-' or input[index] == '7' or input[index] == 'F'))
        // {
        //     return Tile.Squeeze;
        // }
        //
        // if ((index % width == 139 or tiles[index + 1] == Tile.Outside or (tiles[index + 1] == Tile.Squeeze and (input[index + 1] == '-' or input[index + 1] == 'J' or input[index + 1] == 'L'))) and
        //     (index % width == 0 or input[index] == '-' or input[index] == 'L' or input[index] == 'J'))
        // {
        //     return Tile.Squeeze;
        // }
        //
        // if ((index % width == 0 or tiles[index - 1] == Tile.Outside or (tiles[index - 1] == Tile.Squeeze and (input[index - 1] == '-' or input[index - 1] == 'J' or input[index - 1] == 'L'))) and
        //     (index % width == 139 or input[index] == '-' or input[index] == 'L' or input[index] == 'J'))
        // {
        //     return Tile.Squeeze;
        // }
        //
        // if ((index < width or tiles[index - width] == Tile.Outside or (tiles[index - width] == Tile.Squeeze and (input[index - width] == 'J' or input[index - width] == '|' or input[index - width] == '7'))) and (index + width > input.len - 1 or input[index] == '|' or input[index] == '7' or input[index] == 'J')) {
        //     return Tile.Squeeze;
        // }
        //
        // if ((index + width > input.len - 1 or tiles[index + width] == Tile.Outside or (tiles[index + width] == Tile.Squeeze and (input[index + width] == 'J' or input[index + width] == '|' or input[index + width] == '7'))) and
        //     (index < width or input[index] == '|' or input[index] == '7' or input[index] == 'J'))
        // {
        //     return Tile.Squeeze;
        // }
    }

    return tiles[index];
}

pub fn collapse_tile(input: []const u8, tiles: *[]Tile, width: usize, index: usize) void {
    const tile = get_tile_val(input, tiles.*, width, index);
    tiles.*[index] = tile;
}

const Tile = union(enum) {
    Junk,
    Loop,
    Squeeze: Squeezable,
    Inside,
    Outside,
};

const Squeezable = struct {
    Right: bool,
    Left: bool,
    Up: bool,
    Down: bool,
};

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

    pub fn move(turtle: *Turtle, pipe: u8, width: usize) void {
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

const expect = std.testing.expect;
const test_alloc = std.testing.allocator;
