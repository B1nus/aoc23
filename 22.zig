const std = @import("std");

pub fn main() !void {
    var sim = try Simulation.parse(@embedFile("22.txt"), std.heap.page_allocator);
    try sim.simulate();
    // for (sim.settled.items) |b| {
    //     b.print();
    // }
    std.debug.print("{d}\n", .{sim.count_free()});
    // var it = sim.above.iterator();
    // while (it.next()) |aboves| {
    //     for (aboves.value_ptr.*.items) |above| {
    //         std.debug.print("{d} is above {d}\n", .{ above, aboves.key_ptr.* });
    //     }
    // }
    // it = sim.below.iterator();
    // while (it.next()) |belows| {
    //     for (belows.value_ptr.*.items) |below| {
    //         std.debug.print("{d} is above {d}\n", .{ belows.key_ptr.*, below });
    //     }
    // }
}

const Simulation = struct {
    falling: std.ArrayList(Block),
    settled: std.ArrayList(Block),
    above: std.AutoHashMap(usize, std.ArrayList(usize)),
    below: std.AutoHashMap(usize, std.ArrayList(usize)),

    pub fn parse(input: []const u8, allocator: std.mem.Allocator) !@This() {
        var falling = std.ArrayList(Block).init(allocator);
        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |line| {
            if (line.len > 0) {
                try falling.append(try Block.parse(line));
            }
        }
        return @This(){
            .falling = falling,
            .settled = std.ArrayList(Block).init(allocator),
            .above = std.AutoHashMap(usize, std.ArrayList(usize)).init(allocator),
            .below = std.AutoHashMap(usize, std.ArrayList(usize)).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.falling.deinit();
        self.settled.deinit();
    }

    fn less_than_fn(_: void, lhs: Block, rhs: Block) bool {
        return lhs.z.min > rhs.z.min;
    }

    fn sort_blocks(self: *@This()) void {
        std.mem.sort(Block, self.falling.items, {}, less_than_fn);
    }

    fn pop_lowest(self: *@This()) ?Block {
        return self.falling.popOrNull();
    }

    pub fn settle(self: *@This(), block: Block) !void {
        const i = self.settled.items.len;
        try self.below.put(i, std.ArrayList(usize).init(self.settled.allocator));
        try self.above.put(i, std.ArrayList(usize).init(self.settled.allocator));
        var height: usize = 0;
        for (self.settled.items) |*stationary_block| {
            if (block.xy_intersect(stationary_block.*)) {
                height = @max(height, stationary_block.z.max);
            }
        }
        for (self.settled.items, 0..) |*stationary_block, j| {
            if (block.xy_intersect(stationary_block.*) and stationary_block.z.max == height) {
                try self.below.getPtr(i).?.append(j);
                try self.above.getPtr(j).?.append(i);
            }
        }
        var block_ = block;
        block_.fall(height + 1);
        try self.settled.append(block_);
    }

    pub fn simulate(self: *@This()) !void {
        self.sort_blocks();
        while (self.pop_lowest()) |lowest| {
            try self.settle(lowest);
        }
        std.debug.assert(self.falling.items.len == 0);
    }

    pub fn safe_to_disintegrate(self: @This(), index: usize) bool {
        if (self.above.get(index)) |aboves| {
            if (aboves.items.len > 0) {
                for (aboves.items) |block_above| {
                    if (self.below.get(block_above).?.items.len <= 1) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    pub fn count_free(self: @This()) usize {
        var count: usize = 0;
        for (0..self.settled.items.len) |i| {
            if (self.safe_to_disintegrate(i)) count += 1;
        }
        return count;
    }
};

const Block = struct {
    x: Range,
    y: Range,
    z: Range,

    pub fn parse(line: []const u8) !@This() {
        var lr_split = std.mem.splitScalar(u8, line, '~');
        var min_iter = std.mem.splitScalar(u8, lr_split.next().?, ',');
        var max_iter = std.mem.splitScalar(u8, lr_split.next().?, ',');

        const minx = try std.fmt.parseInt(usize, min_iter.next().?, 10);
        const miny = try std.fmt.parseInt(usize, min_iter.next().?, 10);
        const minz = try std.fmt.parseInt(usize, min_iter.next().?, 10);
        const maxx = try std.fmt.parseInt(usize, max_iter.next().?, 10);
        const maxy = try std.fmt.parseInt(usize, max_iter.next().?, 10);
        const maxz = try std.fmt.parseInt(usize, max_iter.next().?, 10);

        std.debug.assert(minx <= maxx);
        std.debug.assert(miny <= maxy);
        std.debug.assert(minz <= maxz);

        return @This(){
            .x = range(minx, maxx),
            .y = range(miny, maxy),
            .z = range(minz, maxz),
        };
    }

    pub fn xy_intersect(self: @This(), other: @This()) bool {
        return self.x.overlaping(other.x) and self.y.overlaping(other.y);
    }

    pub fn fall(self: *@This(), minz: usize) void {
        const delta = self.z.min - minz;
        self.z.sub(delta);
    }

    pub fn print(self: @This()) void {
        std.debug.print("x:", .{});
        self.x.print();
        std.debug.print(" y:", .{});
        self.y.print();
        std.debug.print(" z:", .{});
        self.z.print();
        std.debug.print("\n", .{});
    }
};

pub fn range(min: usize, max: usize) Range {
    std.debug.assert(min <= max);
    return Range{ .min = min, .max = max };
}

const Range = struct {
    min: usize,
    max: usize,

    pub fn overlaping(self: @This(), other: @This()) bool {
        return self.has(other.min) or self.has(other.max) or
            other.has(self.min) or other.has(self.max);
    }

    pub fn has(self: @This(), num: usize) bool {
        return num >= self.min and num <= self.max;
    }

    pub fn sub(self: *@This(), delta: usize) void {
        self.max -= delta;
        self.min -= delta;
    }

    pub fn print(self: @This()) void {
        if (self.min == self.max) {
            std.debug.print("{d}", .{self.min});
        } else {
            std.debug.print("{d}~{d}", .{ self.min, self.max });
        }
    }
};
