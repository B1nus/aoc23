const std = @import("std");

const lower: f80 = 200000000000000;
const upper: f80 = 400000000000000;
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
            if (path1.intersection(path2)) |y| {
                if (y > lower and y < upper) {
                    std.debug.print("({d}) {any}\n{any}\n\n", .{ y, path1, path2 });
                    count += 1;
                }
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

    fn new(h: Hail) @This() {
        const x: f80 = @floatFromInt(h.x);
        const y: f80 = @floatFromInt(h.y);
        const vx: f80 = @floatFromInt(h.vx);
        const vy: f80 = @floatFromInt(h.vy);
        const min_x: f80, const max_x: f80 = if (vx > 0) .{ x, upper } else .{ lower, x };

        return Path{
            .k = vy / vx,
            .m = -vy / vx * x + y,
            .min_x = min_x,
            .max_x = max_x,
        };
    }

    fn intersection(p: Path, o: Path) ?f80 {
        const x = (o.m - p.m) / (p.k - o.k);
        const y = p.k * x + p.m;

        if (x > p.min_x and x < p.max_x and x > o.min_x and x < o.max_x) {
            return y;
        } else {
            return null;
        }
    }
};
// 243923652854078, 279918496708334, 263368855906889 @ -10, -28, -46
// 296252401452864, 327874358550835, 377993052144176 @ 136, -51, -19
// 421277050485032, 273623815775052, 269761614145925 @ -12, 8, 96
// 387591742665614, 247504401752411, 358594078602004 @ 20, 38, -9
// 468809819568290, 385036788868905, 294013914519908 @ -162, -153, 36
// 258179972834194, 52748555929109, 91112819123352 @ 186, 236, 289
// 343980075964643, 281611462452516, 293357299565044 @ -7, -8, 25
// 159369656759875, 310708344226050, 207002556042843 @ -107, -746, -234
// 429653564477054, 237558375007563, 395569581255812 @ 22, 45, -15
// 253462257219200, 293372919569925, 285178285740668 @ -101, -83, -165
// 333199329786495, 291847124221545, 291777020500333 @ -29, -29, 6
// 193637888061726, 293344096223371, 235123461598870 @ 108, -82, 10
