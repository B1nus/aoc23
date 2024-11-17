// Basic constants I almost always use.
const std = @import("std");
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

// The interesting part. ;)
pub fn main() !void {
    const grid, const width, const height = try sanitize_grid(@embedFile("17.txt"), page_allocator);
    for (grid) |*tile| {
        tile.* -= '0';
    }

    // I'm learning Djikstra from https://advent-of-code.xavd.id/writeups/2022/day/12/
    var seen = std.AutoHashMap(Move, void).init(page_allocator);
    var distances = try page_allocator.alloc(usize, grid.len);
    var queue = std.ArrayList(State).init(page_allocator);

    @memset(distances, 0xFFFFFFFF);
    distances[0] = 0;
    try push(&queue, State.new(0, 0, Direction.Down, 0, 0));
    try push(&queue, State.new(0, 0, Direction.Right, 0, 0));

    while (queue.items.len > 0) {
        const state = queue.pop();
        const heat, const move = .{ state.heat, state.move };

        if (move.x == width - 1 and move.y == height - 1) {
            print("Day 17 >> {d}\n", .{heat});
            return;
        }
        if (seen.get(move)) |_| {
            continue;
        }

        try seen.put(move, void{});

        if (move.steps < 3) {
            if (move.dir.new_pos(move.x, move.y, width, height)) |new_pos_| {
                const nx, const ny = .{ new_pos_.x, new_pos_.y };
                try push(&queue, State.new(nx, ny, move.dir, move.steps + 1, heat + grid[nx + ny * width]));
            }
        }

        switch (move.dir) {
            .Up, .Down => {
                if (move.x > 0) {
                    try push(&queue, State.new(move.x - 1, move.y, Direction.Left, 1, heat + grid[move.x - 1 + move.y * width]));
                }
                if (move.x < width - 1) {
                    try push(&queue, State.new(move.x + 1, move.y, Direction.Right, 1, heat + grid[move.x + 1 + move.y * width]));
                }
            },
            .Left, .Right => {
                if (move.y > 0) {
                    try push(&queue, State.new(move.x, move.y - 1, Direction.Up, 1, heat + grid[move.x + (move.y - 1) * width]));
                }
                if (move.y < height - 1) {
                    try push(&queue, State.new(move.x, move.y + 1, Direction.Down, 1, heat + grid[move.x + (move.y + 1) * width]));
                }
            },
        }
    }
}

const Direction = enum {
    Up,
    Left,
    Down,
    Right,

    pub fn new_pos(self: @This(), x: usize, y: usize, width: usize, height: usize) ?struct { x: usize, y: usize } {
        switch (self) {
            .Up => return if (y == 0) null else .{ .x = x, .y = y - 1 },
            .Left => return if (x == 0) null else .{ .x = x - 1, .y = y },
            .Down => return if (y == height - 1) null else .{ .x = x, .y = y + 1 },
            .Right => return if (x == width - 1) null else .{ .x = x + 1, .y = y },
        }
    }
};

const Move = struct {
    x: usize,
    y: usize,
    dir: Direction,
    steps: usize,

    pub fn new(x: usize, y: usize, dir: Direction, steps: usize) @This() {
        return @This(){
            .x = x,
            .y = y,
            .dir = dir,
            .steps = steps,
        };
    }
};

const State = struct {
    heat: usize,
    move: Move,

    pub fn new(x: usize, y: usize, dir: Direction, steps: usize, heat: usize) @This() {
        return @This(){
            .heat = heat,
            .move = Move.new(x, y, dir, steps),
        };
    }
};

// Add an element top the arraylist while making sure that the smallest element is at the top
pub fn push(list: *std.ArrayList(State), state: State) !void {
    for (list.items, 0..) |e, i| {
        if (state.heat >= e.heat) {
            try list.insert(i, state);
            return;
        }
    }
    try list.append(state);
}

// Remove newlines and provide the width and height of the grid.
pub fn sanitize_grid(input: []const u8, allocator: std.mem.Allocator) !struct { []u8, usize, usize } {
    const width = std.mem.indexOfScalar(u8, input, '\n').?;
    const height = (input.len + 1) / (width + 1);

    var chars = try allocator.alloc(u8, width * height);
    var lines = std.mem.splitScalar(u8, input, '\n');
    for (0..height) |y| {
        std.mem.copyForwards(u8, chars[y * width .. (y + 1) * width], lines.next().?);
    }

    return .{ chars, width, height };
}
