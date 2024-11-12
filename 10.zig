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

    // Initialising distance array
    var turtle1 = Turtle.from_diff(start, starts.items[0]);
    var turtle2 = Turtle.from_diff(start, starts.items[1]);
    var steps: usize = 1;

    // I assume the loop cannot be an even number of steps long. If that assumption is wrong, this can be an infinite loop.
    while (turtle1.pos != turtle2.pos) : (steps += 1) {
        turtle1.move(input[turtle1.pos], width);
        turtle2.move(input[turtle2.pos], width);
    }

    print("Day " ++ day ++ " >> {d}\n", .{steps});
}

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
