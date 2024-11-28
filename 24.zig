const std = @import("std");

const lower = Ratio.new_int(200000000000000);
const upper = Ratio.new_int(400000000000000);
// const lower = Ratio.new_int(7);
// const upper = Ratio.new_int(27);

pub fn main() !void {
    var lines = std.mem.splitScalar(u8, @embedFile("24.txt"), '\n');
    var paths = std.ArrayList(Path).init(std.heap.page_allocator);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const hail = try Hail.new(line);
        const path = Path.new(hail);
        try paths.append(path);
        // std.debug.print("{s} {s}\n", .{ try hail.format(), try path.format() });
    }

    var count: usize = 0;
    for (paths.items[1..], 1..) |path1, i| {
        for (paths.items[0..i]) |path2| {
            if (path1.intersecting(path2)) {
                count += 1;
            }
        }
    }

    std.debug.print("{d}\n", .{count});
}

const Hail = struct {
    x: Ratio,
    y: Ratio,
    z: Ratio,
    vx: Ratio,
    vy: Ratio,
    vz: Ratio,

    fn new(t: []const u8) !@This() {
        var it = std.mem.splitSequence(u8, t, " @ ");
        var pos_it = std.mem.splitSequence(u8, it.next().?, ", ");
        var vel_it = std.mem.splitSequence(u8, it.next().?, ", ");
        return @This(){
            .x = try Ratio.parse_int(pos_it.next().?),
            .y = try Ratio.parse_int(pos_it.next().?),
            .z = try Ratio.parse_int(pos_it.next().?),
            .vx = try Ratio.parse_int(vel_it.next().?),
            .vy = try Ratio.parse_int(vel_it.next().?),
            .vz = try Ratio.parse_int(vel_it.next().?),
        };
    }

    fn format(self: @This()) []u8 {
        return std.fmt.allocPrint(std.heap.page_allocator, "({s},{s},{s}) ({s},{s},{s})", .{ self.x.format(), self.y.format(), self.z.format(), self.vx.format(), self.vy.format(), self.vz.format() }) catch {
            unreachable;
        };
    }
};

const Path = struct {
    k: Ratio,
    m: Ratio,
    min_x: Ratio,
    max_x: Ratio,
    min_y: Ratio,
    max_y: Ratio,
    hail: Hail, // For debugging purposes

    fn new(hail: Hail) @This() {
        // if (hail.vz.le(Ratio.new_int(0))) hail.z.negated().div(hail.vz) else
        const max_time = upper;
        // std.debug.print("{d}\n", .{max_time});

        var min_x = max_time.mul(hail.vx).add(hail.x).min(hail.x);
        var max_x = max_time.mul(hail.vx).add(hail.x).max(hail.x);
        var min_y = max_time.mul(hail.vy).add(hail.y).min(hail.y);
        var max_y = max_time.mul(hail.vy).add(hail.y).max(hail.y);

        min_x = min_x.clamp(lower, upper);
        max_x = max_x.clamp(lower, upper);
        min_y = min_y.clamp(lower, upper);
        max_y = max_y.clamp(lower, upper);

        // std.debug.print("{s}\n", .{hail.vy.format() catch {
        //     unreachable;
        // }});
        // std.debug.print("negated => {s}\n", .{hail.vy.negated().format() catch {
        //     unreachable;
        // }});
        // std.debug.print("div {s} => {s}\n", .{ hail.vx.format() catch {
        //     unreachable;
        // }, hail.vy.negated().div(hail.vx).format() catch {
        //     unreachable;
        // } });
        // std.debug.print("mul {s} => {s}\n", .{ hail.x.format() catch {
        //     unreachable;
        // }, hail.vy.negated().div(hail.vx).mul(hail.x).format() catch {
        //     unreachable;
        // } });
        // std.debug.print("add {s} => {s}\n", .{ hail.y.format() catch {
        //     unreachable;
        // }, hail.vy.negated().div(hail.vx).mul(hail.x).add(hail.y).format() catch {
        //     unreachable;
        // } });

        return @This(){
            .k = hail.vy.div(hail.vx),
            .m = hail.vy.negated().div(hail.vx).mul(hail.x).add(hail.y),
            .min_x = min_x,
            .max_x = max_x,
            .min_y = min_y,
            .max_y = max_y,
            .hail = hail,
        };
    }

    fn intersection(self: Path, other: Path) ?struct { Ratio, Ratio } {
        // They are paralell and will never cross
        if (self.k.eql(other.k)) {
            return null;
        } else {
            // std.debug.print("{s}\n", .{self.m.format()});
            // std.debug.print("- {s} = {s}\n", .{ other.m.format(), self.m.sub(other.m).format() });

            const x = self.m.sub(other.m).div(other.k.sub(self.k));
            const y = self.k.mul(x).add(self.m);

            return .{ x, y };
        }
    }

    fn intersecting(self: Path, other: Path) bool {
        if (self.intersection(other)) |intersection_| {
            const x, const y = intersection_;
            std.debug.print("\nchecking intersectio between: \n{s}\nand:\n{s}\n", .{ self.hail.format(), other.hail.format() });
            std.debug.print("intersection: ({s},{s})\n", .{ x.format(), y.format() });
            std.debug.print("self.range.x: ({s},{s})\n", .{ self.min_x.format(), self.max_x.format() });
            std.debug.print("other.range.x: ({s},{s})\n", .{ other.min_x.format(), other.max_x.format() });
            std.debug.print("self.range.y: ({s},{s})\n", .{ self.min_y.format(), self.max_y.format() });
            std.debug.print("other.range.y: ({s},{s})\n", .{ other.min_y.format(), other.max_y.format() });

            return x.in_range(self.min_x, self.max_x) and x.in_range(other.min_x, other.max_x) and y.in_range(self.min_y, self.max_y) and y.in_range(other.min_y, other.max_y);
        } else {
            return false;
        }
    }

    fn format(self: Path) ![]u8 {
        return try std.fmt.allocPrint(std.heap.page_allocator, "y = ({s})x + {s}", .{ self.k.format(), self.m.format() });
    }
};

const ratio = Ratio.new;
const Ratio = struct {
    a: u128,
    b: u128,
    neg: bool,
    // a / b

    fn new(a: u128, b: u128, neg: bool) @This() {
        // No no, division by zero bad
        std.debug.assert(b != 0);

        const gcd = std.math.gcd(a, b);
        const a_ = a / gcd;
        const b_ = b / gcd;
        return @This(){ .a = a_, .b = b_, .neg = neg };
    }

    fn new_int(int: i128) @This() {
        return @This().new(@abs(int), 1, int < 0);
    }

    fn div(self: @This(), other: Ratio) @This() {
        // No no, division by zero bad
        std.debug.assert(other.a != 0);

        const a = self.a * other.b;
        const b = self.b * other.a;
        const neg = self.neg != other.neg;
        return @This().new(a, b, neg);
    }

    fn mul(self: @This(), other: Ratio) @This() {
        const a = self.a * other.a;
        const b = self.b * other.b;
        const neg = self.neg != other.neg;
        return @This().new(a, b, neg);
    }

    fn add(self: @This(), other: @This()) @This() {
        // Use sub instead
        if (other.neg) {
            return self.sub(@This().new(other.a, other.b, true));
        }

        const b = self.b * other.b;
        const a1 = self.a * other.b;
        const a2 = other.a * self.b;

        const a, const neg = if (self.neg and a2 > a1) .{ a2 - a1, false } else if (self.neg) .{ a1 - a2, true } else .{ a1 + a2, false };

        return @This().new(a, b, neg);
    }

    fn sub(self: @This(), other: @This()) @This() {
        // Use add instead
        if (other.neg) {
            return self.add(@This().new(other.a, other.b, false));
        }

        // std.debug.print("\n{s} - {s} = {s}\n", .{ self.format() catch {
        //     unreachable;
        // }, other.format() catch {
        //     unreachable;
        // }, self.negated().add(other).negated().format() catch {
        //     unreachable;
        // } });

        // std.debug.print("!({s}) + !({s}) = !({s})\n", .{ self.format() catch {
        //     unreachable;
        // }, other.format() catch {
        //     unreachable;
        // }, self.negated().add(other.negated()).negated().format() catch {
        //     unreachable;
        // } });
        // std.debug.print("{s} + {s} = {s}\n\n", .{ self.negated().format() catch {
        //     unreachable;
        // }, other.negated().format() catch {
        //     unreachable;
        // }, self.negated().add(other.negated()).format() catch {
        //     unreachable;
        // } });

        // Reusing add
        return self.negated().add(other).negated();
    }

    fn negated(self: @This()) @This() {
        return @This().new(self.a, self.b, !self.neg);
    }

    fn in_range(self: @This(), min_: @This(), max_: @This()) bool {
        // std.debug.print("{s} is in ({s})..({s}) == {}\n", .{ self.format(), min.format(), max.format(), self.le_eql(max) and self.gt_eql(min) });
        return self.le_eql(max_) and self.gt_eql(min_);
    }

    // Equal
    fn eql(self: @This(), other: @This()) bool {
        return self.a == other.a and self.b == other.b and (self.neg == other.neg or self.a == 0);
    }

    // Less than
    fn le(self: @This(), other: @This()) bool {
        const a1 = self.a * other.b;
        const a2 = other.a * self.b;
        return !self.eql(other) and ((self.neg and !other.neg) or (self.neg and other.neg and a1 > a2) or (!self.neg and !other.neg and a1 < a2));
    }

    // Less than or equal
    fn le_eql(self: @This(), other: @This()) bool {
        return le(self, other) or eql(self, other);
    }

    // Greater than
    fn gt(self: @This(), other: @This()) bool {
        const a1 = self.a * other.b;
        const a2 = other.a * self.b;
        return !self.eql(other) and ((!self.neg and other.neg) or (self.neg and other.neg and a1 < a2) or (!self.neg and !other.neg and a1 > a2));
    }

    // Greater than or equal
    fn gt_eql(self: @This(), other: @This()) bool {
        return gt(self, other) or eql(self, other);
    }

    fn clamp(self: @This(), min_: @This(), max_: @This()) @This() {
        std.debug.print("{s} clamped between ({s})..({s})", .{ self.format(), min_.format(), max_.format() });
        if (self.le(min_)) {
            std.debug.print(" is {s}\n", .{min_.format()});
            return min_;
        }

        if (self.gt(max_)) {
            std.debug.print(" is {s}\n", .{max_.format()});
            return max_;
        }

        std.debug.print(" is {s}\n", .{self.format()});
        return self;
    }

    fn max(self: @This(), other: @This()) @This() {
        if (self.gt(other)) {
            return self;
        } else {
            return other;
        }
    }

    fn min(self: @This(), other: @This()) @This() {
        if (self.le(other)) {
            return self;
        } else {
            return other;
        }
    }

    // Parse an integer
    fn parse_int(text: []const u8) !@This() {
        const text_, const neg = if (text[0] == '-') .{ text[1..], true } else .{ text, false };
        const int = try std.fmt.parseInt(u128, text_, 10);
        return @This().new(int, 1, neg);
    }

    fn format(self: @This()) []u8 {
        const ally = std.heap.page_allocator;
        var fmt = std.ArrayList(u8).init(ally);
        if (self.neg) {
            fmt.appendSlice(std.fmt.allocPrint(ally, "-", .{}) catch {
                unreachable;
            }) catch {
                unreachable;
            };
        }
        if (self.b != 1) {
            fmt.appendSlice(std.fmt.allocPrint(ally, "{d}/{d}", .{ self.a, self.b }) catch {
                unreachable;
            }) catch {
                unreachable;
            };
        } else {
            fmt.appendSlice(std.fmt.allocPrint(ally, "{d}", .{self.a}) catch {
                unreachable;
            }) catch {
                unreachable;
            };
        }
        return fmt.items;
    }
};
