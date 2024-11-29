// I cheated again, I'm sorry. I tried my very best. Thank you @HyperNeutrino.
const std = @import("std");

const lower = 200000000000000;
const upper = 400000000000000;
// const lower = 7;
// const upper = 27;

pub fn main() !void {
    var lines = std.mem.splitScalar(u8, @embedFile("24.txt"), '\n');
    var paths = std.ArrayList(Path).init(std.heap.page_allocator);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try paths.append(try Path.new(line));
    }

    var count: usize = 0;
    for (paths.items[1..], 1..) |other, other_i| {
        for (paths.items[0..other_i]) |self| {
            // self.print("{s} and ");
            // other.print("{s}\n");
            if (self.a * other.b == other.a * self.b) {
                // std.debug.print("paralell\n", .{});
                continue;
            } else {
                const x, const y = self.intersection(other);
                if (self.in_future(x, y) and other.in_future(x, y) and x <= upper and x >= lower and y <= upper and y >= lower) {
                    count += 1;
                    // std.debug.print("YUPP ", .{});
                }
                // std.debug.print("x={d} y={d}\n", .{ x, y });
            }
        }
    }

    std.debug.print("{d}\n", .{count});
}

const Path = struct {
    a: f80,
    b: f80,
    c: f80,
    sx: f80,
    sy: f80,
    vx: f80,
    vy: f80,

    fn new(line: []const u8) !@This() {
        var parts = std.mem.splitScalar(u8, line, '@');
        var pos_parts = std.mem.splitScalar(u8, parts.next().?, ',');
        var vel_parts = std.mem.splitScalar(u8, parts.next().?, ',');

        const sx = try std.fmt.parseFloat(f80, std.mem.trim(u8, pos_parts.next().?, " "));
        const sy = try std.fmt.parseFloat(f80, std.mem.trim(u8, pos_parts.next().?, " "));
        // const z = try std.fmt.parseFloat(f80, std.mem.trim(u8, pos_parts.next().?, " "));
        const vx = try std.fmt.parseFloat(f80, std.mem.trim(u8, vel_parts.next().?, " "));
        const vy = try std.fmt.parseFloat(f80, std.mem.trim(u8, vel_parts.next().?, " "));
        // const vz = try std.fmt.parseFloat(f80, std.mem.trim(u8, val_parts.next().?, " "));

        return @This(){ .a = vy, .b = -vx, .c = vy * sx - vx * sy, .sx = sx, .sy = sy, .vx = vx, .vy = vy };
    }

    // I assume they are not paralell
    fn intersection(self: @This(), other: @This()) [2]f80 {
        const div = self.a * other.b - other.a * self.b;
        return .{ (self.c * other.b - other.c * self.b) / div, (other.c * self.a - self.c * other.a) / div };
    }

    fn in_future(self: @This(), x: f80, y: f80) bool {
        return (x - self.sx < 0) == (self.vx < 0) and (y - self.sy < 0) == (self.vy < 0);
    }

    fn print(self: @This(), comptime fmt: []const u8) void {
        std.debug.print(fmt, .{std.fmt.allocPrint(std.heap.page_allocator, "{d}x+{d}={d}", .{ self.a, self.b, self.c }) catch {
            unreachable;
        }});
    }
};
