const std = @import("std");
const stdin = std.io.getStdIn().reader();
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

pub fn main() !void {
    const input = try clean_up_input();
    const width = input.width;
    const height = input.height;
    const chars = input.chars;

    var max: usize = 0;
    for (0..width) |i| {
        max = @max(max, try energized_tiles(Beam{ .dir = Direction.Down, .pos = i }, chars, width, height));
        max = @max(max, try energized_tiles(Beam{ .dir = Direction.Up, .pos = width * height - 1 - i }, chars, width, height));
        max = @max(max, try energized_tiles(Beam{ .dir = Direction.Right, .pos = i * width }, chars, width, height));
        max = @max(max, try energized_tiles(Beam{ .dir = Direction.Left, .pos = i * width + width - 1 }, chars, width, height));
    }

    print("Day 16 >> {d}\n", .{max});
}

pub fn energized_tiles(start_beam: Beam, chars: []const u8, width: usize, height: usize) !usize {
    const energized = try page_allocator.alloc(bool, chars.len);
    for (energized) |*e| {
        e.* = false;
    }

    var beams = std.ArrayList(Beam).init(page_allocator);
    var cached_beams = std.AutoHashMap(Beam, void).init(page_allocator);
    try beams.append(start_beam);
    var beams_to_delete = std.ArrayList(usize).init(page_allocator);

    while (beams.items.len > 0) {
        for (beams.items, 0..) |beam, i| {
            if (try cached_beams.fetchPut(beam, void{})) |_| {
                try beams_to_delete.append(i);
                continue;
            } else {
                energized[beam.pos] = true;
            }
            switch (chars[beams.items[i].pos]) {
                '|' => if (beam.dir == Direction.Left or beam.dir == Direction.Right) {
                    beams.items[i].dir = Direction.Up;
                    try beams.append(Beam{ .dir = Direction.Down, .pos = beams.items[i].pos });
                },
                '-' => if (beam.dir == Direction.Up or beam.dir == Direction.Down) {
                    beams.items[i].dir = Direction.Left;
                    try beams.append(Beam{ .dir = Direction.Right, .pos = beams.items[i].pos });
                },
                '/' => switch (beam.dir) {
                    .Up => beams.items[i].dir = Direction.Right,
                    .Down => beams.items[i].dir = Direction.Left,
                    .Left => beams.items[i].dir = Direction.Down,
                    .Right => beams.items[i].dir = Direction.Up,
                },
                '\\' => switch (beam.dir) {
                    .Up => beams.items[i].dir = Direction.Left,
                    .Down => beams.items[i].dir = Direction.Right,
                    .Left => beams.items[i].dir = Direction.Up,
                    .Right => beams.items[i].dir = Direction.Down,
                },
                else => {},
            }
        }
        for (beams.items, 0..) |beam, i| {
            if (walk_beam(beam.pos, beam.dir, width, height)) |new_pos| {
                beams.items[i].pos = new_pos;
            } else if (std.mem.count(usize, beams_to_delete.items, &.{i}) == 0) {
                try beams_to_delete.append(i);
            }
            //
            // for (chars, 0..) |c, j| {
            //     if (energized[j]) {
            //         print("\x1b[31m{c}\x1b[0m", .{c});
            //     } else {
            //         print("{c}", .{c});
            //     }
            //     if (j % width == width - 1) {
            //         print("\n", .{});
            //     }
            // }
            //
            // _ = try stdin.readByte();
        }
        std.mem.sort(usize, beams_to_delete.items, {}, comptime std.sort.asc(usize));
        while (beams_to_delete.popOrNull()) |del_index| {
            _ = beams.orderedRemove(del_index);
        }
    }

    return std.mem.count(bool, energized, &.{true});
}

const Beam = struct {
    dir: Direction,
    pos: usize,
};

pub fn walk_beam(beam_pos: usize, dir: Direction, width: usize, height: usize) ?usize {
    return switch (dir) {
        .Up => if (beam_pos < width) null else beam_pos - width,
        .Down => if (beam_pos + width >= width * height) null else beam_pos + width,
        .Left => if (beam_pos % width == 0) null else beam_pos - 1,
        .Right => if (beam_pos % width == width - 1) null else beam_pos + 1,
    };
}

const Direction = enum {
    Up,
    Down,
    Left,
    Right,
};

pub fn clean_up_input() !struct { chars: []const u8, width: usize, height: usize } {
    const input = @embedFile("16.txt");
    const width = std.mem.indexOfScalar(u8, input, '\n').?;
    const height = (input.len + 1) / (width + 1);

    var chars = try page_allocator.alloc(u8, width * height);
    for (0..width) |x| {
        for (0..height) |y| {
            chars[y * width + x] = input[x + y * (width + 1)];
        }
    }

    return .{ .chars = chars, .width = width, .height = height };
}
