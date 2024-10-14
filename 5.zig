const std = @import("std");
const stdout = std.io.getStdOut().writer();
var buffer: [8 * 20]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    var min: usize = undefined;

    var lines = std.mem.splitScalar(u8, input, '\n');
    var seeds = std.ArrayList(usize).init(allocator);

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.eql(u8, line[0..5], "seeds")) {
            var seed_iter = std.mem.splitScalar(u8, line[7..], ' ');
            while (seed_iter.next()) |seed| {
                try seeds.append(try std.fmt.parseInt(usize, seed, 10));
                std.debug.print("{d} ", .{seeds.getLast()});
            }
            std.debug.print("\n", .{});
        }
        switch (line[0]) {
            '0'...'9' => {
                var maping = std.mem.splitScalar(u8, line, ' ');
                const dest_range_start = try std.fmt.parseInt(usize, maping.next().?, 10);
                const source_range_start = try std.fmt.parseInt(usize, maping.next().?, 10);
                const range_length = try std.fmt.parseInt(usize, maping.next().?, 10);
                std.debug.print("de: {d} so: {d} le: {d}... ", .{ dest_range_start, source_range_start, range_length });
                for (seeds.items) |*seed| {
                    if (seed.* >= source_range_start and seed.* < source_range_start + range_length) {
                        std.debug.print("{d} -> {d}  ", .{ seed.*, (seed.* + dest_range_start) - source_range_start });
                        seed.* += dest_range_start;
                        seed.* -= source_range_start;
                    }
                }
                std.debug.print("\n", .{});
            },
            else => continue,
        }
    }

    for (seeds.items) |seed| {
        if (seed < min) {
            min = seed;
        }
    }

    std.debug.print("Day " ++ day ++ " -> {d}\n", .{min});
}
