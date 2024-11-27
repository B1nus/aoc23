const std = @import("std");

const lower: f80 = 200000000000000;
const upper: f80 = 2 * lower;
// const lower: f80 = 7;
// const upper: f80 = 24;

pub fn main() !void {
    var lines = std.mem.splitScalar(u8, @embedFile("24.txt"), '\n');
    var paths = std.ArrayList(Path).init(std.heap.page_allocator);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const hail = try Hail.new(line);
        const path = Path.new(hail);
        try paths.append(path);
    }

    var count: usize = 0;
    for (paths.items[1..], 1..) |path1, i| {
        for (paths.items[0..i]) |path2| {
            if (path1.intersection(path2)) {
                // std.debug.print("{any}\n{any}\n\n", .{ path1, path2 });
                count += 1;
            }
        }
    }

    std.debug.print("{d}\n", .{count});
}

const Hail = struct {
    x: usize,
    y: usize,
    z: usize,
    vx: isize,
    vy: isize,
    vz: isize,

    fn new(t: []const u8) !@This() {
        var it = std.mem.splitSequence(u8, t, " @ ");
        var pos_it = std.mem.splitSequence(u8, it.next().?, ", ");
        var vel_it = std.mem.splitSequence(u8, it.next().?, ", ");
        return @This(){
            .x = try std.fmt.parseInt(usize, pos_it.next().?, 10),
            .y = try std.fmt.parseInt(usize, pos_it.next().?, 10),
            .z = try std.fmt.parseInt(usize, pos_it.next().?, 10),
            .vx = try std.fmt.parseInt(isize, vel_it.next().?, 10),
            .vy = try std.fmt.parseInt(isize, vel_it.next().?, 10),
            .vz = try std.fmt.parseInt(isize, vel_it.next().?, 10),
        };
    }
};

const Path = struct {
    k: f80,
    m: f80,
    min_x: f80,
    max_x: f80,
    min_y: f80,
    max_y: f80,

    fn new(h: Hail) @This() {
        const vz: f80 = @floatFromInt(h.vz);
        const z: f80 = @floatFromInt(h.z);
        const max_time: f80 = if (h.vz < 0) -z / vz else upper;
        // std.debug.print("{d}\n", .{max_time});

        const x: f80 = @floatFromInt(h.x);
        const y: f80 = @floatFromInt(h.y);
        const vx: f80 = @floatFromInt(h.vx);
        const vy: f80 = @floatFromInt(h.vy);
        const min_x = @max(lower, @min(x, x + vx * max_time));
        const max_x = @min(upper, @max(x, x + vx * max_time));
        const min_y = @max(lower, @min(y, y + vy * max_time));
        const max_y = @min(upper, @max(y, y + vy * max_time));

        return @This(){
            .k = vy / vx,
            .m = -vy / vx * x + y,
            .min_x = min_x,
            .max_x = max_x,
            .min_y = min_y,
            .max_y = max_y,
        };
    }

    fn intersection(p: Path, o: Path) bool {
        const x = (o.m - p.m) / (p.k - o.k);
        const y = p.k * x + p.m;

        // std.debug.print("({d}, {d})", .{ x, y });
        return x >= p.min_x and x <= p.max_x and x >= o.min_x and x <= o.max_x and y >= p.min_y and y <= p.max_y and y >= o.min_y and y <= o.max_y;
    }
};
