// I cheated again, I'm sorry. I tried my very best. Thank you @HyperNeutrino.
//
// For part 2 I found a video by @Werner Altewischer on youtube. Great insight,
// thanks!
const std = @import("std");
const range = 400;

pub fn main() !void {
    var lines = std.mem.splitScalar(u8, @embedFile("24.txt"), '\n');
    var paths = std.ArrayList(Path).init(std.heap.page_allocator);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try paths.append(try Path.new(line));
    }

    // Basically, you can say that the stone is stationary and just subtract every hailstone velocity instead.
    //
    // So, we do that for the xy axis by checking every velocity from -1000 to 1000 in x and y and check
    // if all hailstones collide and if so, if the collide at the same x and y position.
    //
    // This is all from the video by @Werner Altewischer.
    var vx: i128 = @intCast(range);
    var vy: i128 = undefined;
    var vz: i128 = undefined;
    for (0..range * 2) |_| {
        vy = @intCast(range);
        for (0..range * 2) |_| {
            vz = @intCast(range);
            for (0..range * 2) |_| {
                if (try_velocity(paths.items, vx, vy, vz)) |pos| {
                    std.debug.print("Day 24 >> {d}\n", .{pos[0] + pos[1] + pos[2]});
                    std.process.exit(0);
                }
                vz -= 1;
            }
            vy -= 1;
        }
        vx -= 1;
    }
}

fn try_velocity(paths: []Path, vx: i128, vy: i128, vz: i128) ?[3]i128 {
    var pos: ?[3]i128 = null;
    for (paths[1..], 1..) |other, other_i| {
        for (paths[0..other_i]) |self| {
            if (self.intersection(other, vx, vy, vz)) |intersection| {
                if (pos) |p| {
                    if (!std.mem.eql(i128, &intersection, &p)) {
                        return null;
                    }
                } else {
                    pos = intersection;
                }
            } else {
                return null;
            }
        }
    }
    return pos.?;
}

fn eql(a: ?[2]i128, b: ?[2]i128) bool {
    if (a) |a_| {
        if (b) |b_| {
            return a_[0] == b_[0] and a_[1] == b_[1];
        } else {
            return true;
        }
    } else {
        return true;
    }
}

const Path = struct {
    sx: i128,
    sy: i128,
    sz: i128,
    vx: i128,
    vy: i128,
    vz: i128,

    fn new(line: []const u8) !@This() {
        var parts = std.mem.splitScalar(u8, line, '@');
        var pos_parts = std.mem.splitScalar(u8, parts.next().?, ',');
        var vel_parts = std.mem.splitScalar(u8, parts.next().?, ',');

        const sx = try std.fmt.parseInt(i128, std.mem.trim(u8, pos_parts.next().?, " "), 10);
        const sy = try std.fmt.parseInt(i128, std.mem.trim(u8, pos_parts.next().?, " "), 10);
        const sz = try std.fmt.parseInt(i128, std.mem.trim(u8, pos_parts.next().?, " "), 10);
        const vx = try std.fmt.parseInt(i128, std.mem.trim(u8, vel_parts.next().?, " "), 10);
        const vy = try std.fmt.parseInt(i128, std.mem.trim(u8, vel_parts.next().?, " "), 10);
        const vz = try std.fmt.parseInt(i128, std.mem.trim(u8, vel_parts.next().?, " "), 10);

        return @This(){ .sx = sx, .sy = sy, .sz = sz, .vx = vx, .vy = vy, .vz = vz };
    }

    fn intersection(self: @This(), other: @This(), vx: i128, vy: i128, vz: i128) ?[3]i128 {
        var x, var y, var z = [_]?i128{null} ** 3;

        const self_vx = self.vx - vx;
        const self_vy = self.vy - vy;
        const self_vz = self.vz - vz;

        const other_vx = other.vx - vx;
        const other_vy = other.vy - vy;
        const other_vz = other.vz - vz;

        const xy = projected_intersection(self.sx, self_vx, self.sy, self_vy, other.sx, other_vx, other.sy, other_vy);
        const yz = projected_intersection(self.sy, self_vy, self.sz, self_vz, other.sy, other_vy, other.sz, other_vz);
        const zx = projected_intersection(self.sz, self_vz, self.sx, self_vx, other.sz, other_vz, other.sx, other_vx);

        if (xy) |xy_| x, y = xy_;
        if (yz) |yz_| y, z = yz_;
        if (zx) |zx_| z, x = zx_;

        if (x != null and y != null and z != null) {
            return .{ x.?, y.?, z.? };
        } else {
            return null;
        }
    }

    fn projected_intersection(x1: i128, vx1: i128, y1: i128, vy1: i128, x2: i128, vx2: i128, y2: i128, vy2: i128) ?[2]i128 {
        if (vy1 * vx2 == vy2 * vx1) {
            return null;
        } else {
            const a1 = vy1;
            const b1 = -vx1;
            const c1 = vy1 * x1 - vx1 * y1;

            const a2 = vy2;
            const b2 = -vx2;
            const c2 = vy2 * x2 - vx2 * y2;

            const div = a1 * b2 - a2 * b1;

            // They are paralell if div is zero, don't proceed.
            if (div != 0) {
                const x_top = c1 * b2 - c2 * b1;
                const y_top = c2 * a1 - c1 * a2;
                const x = std.math.divExact(i128, x_top, div) catch {
                    return null;
                };
                const y = std.math.divExact(i128, y_top, div) catch {
                    return null;
                };
                return .{ x, y };
            }

            // Either div was zero of x or y was not integers. Either way, return null for no intersection.
            return null;
        }
    }

    fn in_future(self: @This(), x: i128, y: i128, z: i128, vx: i128, vy: i128, vz: i128) bool {
        return (x - self.sx < 0) == (self.vx - vx < 0) and (y - self.sy < 0) == (self.vy - vy < 0) and (z - self.sz) == (self.vz - vz < 0);
    }
};
