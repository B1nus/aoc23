// Please note that I cheated on this one. I'm not good at recursion. I don't seem to good with hashmaps either.
const std = @import("std");
const print = std.debug.print;
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var cache = std.HashMap(State, usize, State.HashContext, std.hash_map.default_max_load_percentage).init(allocator);
    defer cache.deinit();

    var lines = std.mem.splitScalar(u8, @embedFile("12.txt"), '\n');
    var sum: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;
        const state = try parse_and_unfold(line, allocator);
        const count_ = try count(state, &cache);
        sum += count_;
    }
    print("Day 12 >> {d}\n", .{sum});
}

pub fn parse(line: []const u8, allocator: std.mem.Allocator) !State {
    var line_iter = std.mem.splitScalar(u8, line, ' ');
    const cfg_len = std.mem.indexOfScalar(u8, line, ' ').?;
    const cfg = try allocator.alloc(u8, cfg_len);
    std.mem.copyForwards(u8, cfg, line_iter.next().?);

    var nums_iter = std.mem.splitScalar(u8, line_iter.next().?, ',');
    const nums_count = std.mem.count(u8, nums_iter.buffer, ",") + 1;
    const nums = try allocator.alloc(usize, nums_count);
    for (nums) |*num| {
        num.* = try std.fmt.parseInt(usize, nums_iter.next().?, 10);
    }
    return State{ .cfg = cfg, .nums = nums };
}

pub fn parse_and_unfold(line: []const u8, allocator: std.mem.Allocator) !State {
    var line_iter = std.mem.splitScalar(u8, line, ' ');
    const cfg_len = std.mem.indexOfScalar(u8, line, ' ').?;
    var cfg = try allocator.alloc(u8, cfg_len * 5 + 4);
    std.mem.copyForwards(u8, cfg, line_iter.next().?);
    cfg[cfg_len] = '?';
    for (cfg_len + 1..cfg.len) |i| {
        cfg[i] = cfg[i % (cfg_len + 1)];
    }
    var nums_iter = std.mem.splitScalar(u8, line_iter.next().?, ',');
    const nums_count = std.mem.count(u8, nums_iter.buffer, ",") + 1;
    const nums = try allocator.alloc(usize, nums_count * 5);
    for (nums, 0..) |*num, i| {
        if (nums_iter.next()) |num_str| {
            num.* = try std.fmt.parseInt(usize, num_str, 10);
        } else {
            num.* = nums[i % nums_count];
        }
    }
    return State{ .cfg = cfg, .nums = nums };
}

const State = struct {
    cfg: []const u8,
    nums: []const usize,

    pub const HashContext = struct {
        pub fn hash(_: HashContext, self: State) u64 {
            var h = std.hash.Wyhash.init(0);
            h.update(self.cfg);
            h.update(std.mem.asBytes(self.nums));
            return h.final();
        }

        pub fn eql(_: HashContext, self: State, other: State) bool {
            return std.mem.eql(u8, self.cfg, other.cfg) and
                std.mem.eql(usize, self.nums, other.nums);
        }
    };
};

pub fn count(state: State, cache: *std.HashMap(State, usize, State.HashContext, std.hash_map.default_max_load_percentage)) !usize {
    if (state.cfg.len == 0) {
        return if (state.nums.len == 0) 1 else 0;
    }
    if (state.nums.len == 0) {
        return if (std.mem.count(u8, state.cfg, "#") > 0) 0 else 1;
    }

    if (cache.get(state)) |result| {
        return result;
    } else {
        var result: usize = 0;

        if (state.cfg[0] == '.' or state.cfg[0] == '?') {
            result += try count(State{ .cfg = state.cfg[1..], .nums = state.nums }, cache);
        }
        if (state.cfg[0] == '#' or state.cfg[0] == '?') {
            if (state.nums[0] <= state.cfg.len and std.mem.count(u8, state.cfg[0..state.nums[0]], ".") == 0 and (state.nums[0] == state.cfg.len or state.cfg[state.nums[0]] != '#')) {
                if (state.nums[0] + 1 >= state.cfg.len) {
                    result += try count(State{ .cfg = "", .nums = state.nums[1..] }, cache);
                } else {
                    result += try count(State{ .cfg = state.cfg[state.nums[0] + 1 ..], .nums = state.nums[1..] }, cache);
                }
            }
        }

        try cache.put(state, result);

        return result;
    }
}
