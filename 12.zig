const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..2];
    const input = @embedFile(day ++ ".txt");
    const allocator = std.heap.page_allocator;

    var sum: usize = 0;
    var line_num: usize = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const parsed = try Line.from_line(line, allocator);
        sum += try parsed.count_configurations(allocator);
        line_num += 1;
        print("\nline={d}\n", .{line_num});
    }

    print("Day " ++ day ++ " >> {d}\n", .{sum});
}

const Line = struct {
    broken: u128,
    unknown: u128,
    length: usize,
    lengths: []usize,
    allocator: std.mem.Allocator,

    pub fn from_line(line: []const u8, allocator: std.mem.Allocator) !Line {
        var parts = std.mem.splitScalar(u8, line, ' ');
        const symbols = parts.next().?;
        const lengths_str = parts.next().?;

        var length: usize = 0;
        var broken: u128 = 0;
        var unknown: u128 = 0;
        for (0..5) |i| {
            for (symbols) |c| {
                broken = broken << 1;
                unknown = unknown << 1;
                length += 1;
                switch (c) {
                    '?' => unknown ^= 1,
                    '#' => broken ^= 1,
                    '.' => {},
                    else => unreachable,
                }
            }
            if (i != 4) {
                broken = broken << 1;
                unknown = unknown << 1;
                length += 1;
                unknown ^= 1;
            }
        }

        const lengths_count = std.mem.count(u8, lengths_str, ",") + 1;
        var lengths = try allocator.alloc(usize, lengths_count * 5);
        var lengths_iter = std.mem.splitScalar(u8, lengths_str, ',');
        for (0..lengths_count) |i| {
            lengths[i] = try std.fmt.parseInt(usize, lengths_iter.next().?, 10);
        }
        for (1..5) |r| {
            for (0..lengths_count) |i| {
                lengths[i + r * lengths_count] = lengths[i];
            }
        }

        return Line{
            .broken = broken,
            .unknown = unknown,
            .length = length,
            .lengths = lengths,
            .allocator = allocator,
        };
    }

    pub fn print_line(self: Line) void {
        for (0..self.length) |i| {
            const shift: u7 = @intCast(self.length - 1 - i);
            const broken = (self.broken >> shift) & 1 == 1;
            const unknown = (self.unknown >> shift) & 1 == 1;

            if (broken) {
                print(".", .{});
            } else if (unknown) {
                print("?", .{});
            } else {
                print("#", .{});
            }
        }
        print(" {d}", .{self.lengths[0]});
        for (self.lengths[1..]) |l| {
            print(",{d}", .{l});
        }
        print("\n", .{});
    }

    pub fn count_configurations(self: Line, allocator: std.mem.Allocator) !usize {
        var pos_iter = try PositionIterator.new(self.lengths, self.length, allocator);
        defer pos_iter.deinit();

        var configuration_count: usize = 0;
        while (pos_iter.next()) |pos_conf| {
            // pos_iter.print_position_configuration();
            const configuration_bits = position_config_to_bits(pos_conf, self.lengths, self.length);
            if (self.try_configuration(configuration_bits)) {
                configuration_count += 1;
            }
        }
        return configuration_count;
    }

    pub fn try_configuration(self: Line, configuration_bits: u128) bool {
        return configuration_bits & ~self.broken & ~self.unknown == 0;
    }

    pub fn deinit(self: Line) void {
        self.allocator.free(self.lengths);
    }
};

const PositionIterator = struct {
    positions: []usize,
    lengths: []usize,
    length: usize,
    depth: usize,
    allocator: std.mem.Allocator,
    pub fn new(lengths: []usize, length: usize, allocator: std.mem.Allocator) !PositionIterator {
        // I'm assuming that the lengths fit, which is always the case here.
        var positions = try allocator.alloc(usize, lengths.len);

        positions[0] = 0;
        for (lengths[0 .. lengths.len - 2], 1..) |l, i| {
            positions[i] = positions[i - 1] + l + 1;
        }
        positions[positions.len - 1] = length + 1 - lengths[lengths.len - 1];

        return PositionIterator{
            .positions = positions,
            .lengths = lengths,
            .length = length,
            .allocator = allocator,
            .depth = 0,
        };
    }

    pub fn print_position_configuration(self: PositionIterator) void {
        var x: usize = 0;
        for (self.positions, 0..) |p, i| {
            while (x < p) {
                print(".", .{});
                x += 1;
            }
            for (0..self.lengths[i]) |_| {
                print("#", .{});
                x += 1;
            }
        }
        for (x..self.length) |_| {
            print(".", .{});
        }
        print("\n", .{});
    }

    pub fn next(self: *PositionIterator) ?[]usize {
        const pos_conf = self.positions;
        self.positions[self.positions.len - 1] -= 1;
        var depth: usize = 0;
        while (depth + 1 <= self.lengths.len) {
            if (self.positions[self.positions.len - 2] + self.lengths[self.positions.len - 2] == self.positions[self.positions.len - 1]) {
                if (depth + 2 > self.positions.len) {
                    return null;
                }
                self.positions[self.positions.len - 2 - depth] += 1;
                self.positions[self.positions.len - 1] = self.length - self.lengths[self.lengths.len - 1];
                for (0..depth) |i| {
                    self.positions[self.positions.len - 2 - depth + i + 1] = self.positions[self.positions.len - 2 - depth + i] + self.lengths[self.lengths.len - 2 - depth + i] + 1;
                }
                depth += 1;
                if (depth > self.depth) {
                    self.depth = depth;
                    print("#", .{});
                }
                continue;
            }
            break;
        } else {
            return null;
        }
        return pos_conf;
    }

    pub fn deinit(self: PositionIterator) void {
        self.allocator.free(self.positions);
    }
};

pub fn position_config_to_bits(positions: []usize, lengths: []usize, length: usize) u128 {
    var bits: u128 = 0;
    var x: usize = 0;
    for (positions, 0..) |p, i| {
        while (x < p) {
            bits = bits << 1;
            x += 1;
        }
        for (0..lengths[i]) |_| {
            bits = bits << 1;
            bits ^= 1;
            x += 1;
        }
    }
    return bits << @intCast(length - x);
}
