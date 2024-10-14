const std = @import("std");
const stdout = std.io.getStdOut().writer();
var buffer: [1000]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    var min: usize = undefined;

    var lines = std.mem.splitScalar(u8, input, '\n');
    var seeds = std.ArrayList(usize).init(allocator);
    var seed_stop = std.ArrayList(bool).init(allocator);

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.eql(u8, line[0..5], "seeds")) {
            var seed_iter = std.mem.splitScalar(u8, line[7..], ' ');
            while (seed_iter.next()) |seed| {
                try seeds.append(try std.fmt.parseInt(usize, seed, 10));
                try seed_stop.append(false);
            }
        }
        switch (line[0]) {
            '0'...'9' => {
                var maping = std.mem.splitScalar(u8, line, ' ');
                const dest_range_start = try std.fmt.parseInt(usize, maping.next().?, 10);
                const source_range_start = try std.fmt.parseInt(usize, maping.next().?, 10);
                const range_length = try std.fmt.parseInt(usize, maping.next().?, 10);
                for (seeds.items, seed_stop.items) |*seed, *stop| {
                    if (!stop.* and seed.* >= source_range_start and seed.* < source_range_start + range_length) {
                        seed.* += dest_range_start;
                        seed.* -= source_range_start;
                        stop.* = true;
                    }
                }
            },
            else => {
                for (seed_stop.items) |*stop| {
                    stop.* = false;
                }
            },
        }
    }

    for (seeds.items) |seed| {
        if (seed < min) {
            min = seed;
        }
    }

    std.debug.print("Day " ++ day ++ " -> {d}\n", .{min});
}
