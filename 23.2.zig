const std = @import("std");

pub fn main() !void {
    const ally = std.heap.page_allocator;
    var g = try Grid.parse(@embedFile("23.txt"), ally);
    g.print(null);
    const max = try g.longest_path(State.new(1, 0, down, ally));
    std.debug.print("{d}\n", .{max.?});
}

const Grid = struct {
    w: u8,
    h: u8,
    b: []u8,
    ally: std.mem.Allocator,
    max: std.AutoHashMap(struct { u8, u8, Direction }, usize),

    fn parse(in: []const u8, ally: std.mem.Allocator) !@This() {
        const w: u8 = @intCast(std.mem.indexOfScalar(u8, in, '\n').?);
        var bytes = try std.ArrayList(u8).initCapacity(ally, in.len);
        var lines = std.mem.splitScalar(u8, in, '\n');
        while (lines.next()) |line| {
            try bytes.appendSlice(line);
        }
        const h: u8 = @intCast(bytes.items.len / @as(usize, @intCast(w)));
        const max = std.AutoHashMap(struct { u8, u8, Direction }, usize).init(ally);
        return @This(){ .w = w, .h = h, .b = bytes.items, .max = max, .ally = ally };
    }

    fn get(g: @This(), x: u8, y: u8, d: ?Direction) ?u8 {
        if (d) |direction| {
            if (direction.walk(x, y)) |new| {
                const nx, const ny = new;
                // std.debug.print("{any}\n", .{new});
                return if (nx >= g.w or ny >= g.h) null else g.b[@as(usize, @intCast(nx)) + @as(usize, @intCast(ny)) * @as(usize, @intCast(g.w))];
            } else {
                return null;
            }
        } else {
            return if (x >= g.w or y >= g.h) null else g.b[@as(usize, @intCast(x)) + @as(usize, @intCast(y)) * @as(usize, @intCast(g.w))];
        }
    }

    fn longest_path(grid: *@This(), state: State) !?usize {
        if (grid.max.get(.{ state.x, state.y, state.d })) |max| {
            return max;
        } else if (state.y == grid.h - 1) {
            return state.visited.count();
        } else {
            var max: ?usize = null;
            // std.debug.print("x:{d} y:{d} d:{s}\n", .{ state.x, state.y, @tagName(state.d) });
            // std.debug.print("for (state.d.view()) |d|:\n", .{});
            for (state.d.view()) |d| {
                // std.debug.print("  {s}\n", .{@tagName(d)});
                if (grid.get(state.x, state.y, d)) |c| {
                    // std.debug.print("c = {c}\n", .{c});
                    if (c != '#') {
                        if (try state.visit(d, grid.ally)) |ns| {
                            if (try grid.longest_path(ns)) |m| {
                                max = @max(max orelse 0, m);
                            }
                        }
                    }
                } else {
                    // std.debug.print("x:{d} y:{d} w:{d}, h:{d}\n", .{ state.x, state.y, grid.w, grid.h });
                }
            }

            if (max) |m| {
                try grid.max.put(.{ state.x, state.y, state.d }, m);
                return m;
            } else {
                // std.debug.print("{any}\n", .{state});
                return null;
            }
        }
    }

    fn print(g: @This(), path: ?std.AutoHashMap(struct { u8, u8 }, void)) void {
        for (0..g.h) |y| {
            for (0..g.w) |x| {
                if (path) |path_| {
                    if (path_.get(.{ @as(u8, @intCast(x)), @as(u8, @intCast(y)) })) |_| {
                        std.debug.print("*", .{});
                        continue;
                    }
                }
                std.debug.print("{c}", .{g.get(@intCast(x), @intCast(y), null).?});
            }
            std.debug.print("\n", .{});
        }
    }
};

const State = struct {
    x: u8,
    y: u8,
    d: Direction,
    visited: Visited,

    const Visited = std.AutoHashMap(struct { u8, u8 }, void);

    fn new(x: u8, y: u8, d: Direction, ally: std.mem.Allocator) @This() {
        return @This(){
            .x = x,
            .y = y,
            .d = d,
            .visited = Visited.init(ally),
        };
    }

    fn clone(s: @This(), ally: std.mem.Allocator) !@This() {
        var s_ = State.new(s.x, s.y, s.d, ally);
        var it = s.visited.iterator();
        while (it.next()) |i| {
            try s_.visited.put(i.key_ptr.*, i.value_ptr.*);
        }
        return s_;
    }

    fn visit(s: @This(), d: Direction, ally: std.mem.Allocator) !?@This() {
        var s_ = try s.clone(ally);

        switch (d) {
            .up => s_.y -= 1,
            .down => s_.y += 1,
            .left => s_.x -= 1,
            .right => s_.x += 1,
        }

        if (s_.visited.get(.{ s_.x, s_.y })) |_| {
            return null;
        } else {
            s_.d = d;

            try s_.visited.put(.{ s_.x, s_.y }, void{});

            return s_;
        }
    }
};

const up = Direction.up;
const down = Direction.down;
const right = Direction.right;
const left = Direction.left;
const Direction = enum(u8) {
    up,
    down,
    right,
    left,

    fn opposite(d: @This()) @This() {
        return switch (d) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        };
    }

    fn view(d: @This()) [3]Direction {
        return switch (d) {
            .up, .down => .{ Direction.left, Direction.right, d },
            .left, .right => .{ Direction.up, Direction.down, d },
        };
    }

    fn walk(d: @This(), x: u8, y: u8) ?struct { u8, u8 } {
        return switch (d) {
            .up => if (y > 0) .{ x, y - 1 } else null,
            .down => .{ x, y + 1 },
            .left => if (x > 0) .{ x - 1, y } else null,
            .right => .{ x + 1, y },
        };
    }
};
