const std = @import("std");
const stdout = std.io.getStdOut().writer();
var buffer: [10000]u8 = undefined;

const range = struct {
    start: usize,
    length: usize,

    fn from_start_end(start: usize, _end: usize) ?range {
        if (start < _end) {
            return null;
        } else {
            return range{ .start = start, .length = _end - start + 1 };
        }
    }

    fn overlap(self: range, other: *const range) ?range {
        if (self.end() < other.start or self.start > other.end()) {
            return null;
        } else {
            return from_start_end(@max(self.start, other.start), @min(self.end(), other.end()));
        }
    }

    fn backlap(self: range, other: *const range) ?range {
        if (self.start < other.start) {
            return range.from_start_end(self.start, other.start - 1);
        } else {
            return null;
        }
    }

    fn frontlap(self: range, other: *const range) ?range {
        if (self.end() > other.end()) {
            return range.from_start_end(other.end(), self.end());
        } else {
            return null;
        }
    }

    fn end(self: range) usize {
        return self.start + self.length - 1;
    }
};

const conversion = struct {
    source_range: range,
    destination_start: usize,

    fn convert_range(self: conversion, seed_range: *range) void {
        seed_range.start += self.destination_start;
        seed_range.start -= self.source_range.start;
    }

    fn parse_paragraph(paragraph: []const u8, allocator: std.mem.Allocator) !std.ArrayList(conversion) {
        var conversions = std.ArrayList(conversion).init(allocator);
        var lines = std.mem.splitScalar(u8, paragraph, '\n');

        while (lines.next()) |line| {
            // std.debug.print("reading conversion line: {s}\n", .{line});
            if (line.len == 0 or line[0] < 48 or line[0] > 57) break;
            var numbers = std.mem.splitScalar(u8, line, ' ');

            const destination_start = try std.fmt.parseInt(usize, numbers.next().?, 10);
            const source_start = try std.fmt.parseInt(usize, numbers.next().?, 10);
            const length = try std.fmt.parseInt(usize, numbers.next().?, 10);

            // std.debug.print("got conversion: {d} {d} {d}\n", .{ destination_start, source_start, length });

            try conversions.append(conversion{
                .source_range = range{
                    .start = source_start,
                    .length = length,
                },
                .destination_start = destination_start,
            });
        }

        // std.debug.print("parse_paragraph = {any}\n", .{conversions.items});

        return conversions;
    }
};

pub fn main() !void {
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    var min: usize = undefined;

    var paragraphs = std.mem.splitSequence(u8, input, ":\n");
    var seed_ranges = std.ArrayList(range).init(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    const seed_ranges_line = lines.next().?[7..];
    var seed_iter = std.mem.splitScalar(u8, seed_ranges_line, ' ');
    while (seed_iter.next()) |seed| {
        const start = try std.fmt.parseInt(usize, seed, 10);
        const length = try std.fmt.parseInt(usize, seed_iter.next().?, 10);
        try seed_ranges.append(range{ .start = start, .length = length });
    }

    // std.debug.print("seeds:\n", .{});
    // for (seed_ranges.items) |seed_range| std.debug.print("\t{!}\n", .{seed_range});

    while (paragraphs.next()) |paragraph| {
        const conversions = try conversion.parse_paragraph(paragraph, allocator);
        var next_seed_ranges = std.ArrayList(range).init(allocator);
        var potential_seed_ranges = std.ArrayList(range).init(allocator);
        for (seed_ranges.items) |seed_range| {
            std.debug.print("converting seed {!}\n", .{seed_range});
            for (conversions.items) |_conversion| {
                std.debug.print("on conversion {!}\n", .{_conversion});
                var i: usize = 0;
                while (i < potential_seed_ranges.capacity) : (i += 1) {
                    var remove: bool = false;
                    const potential_seed_range = potential_seed_ranges.items[i];
                    if (potential_seed_range.overlap(&_conversion.source_range)) |overlap_range| {
                        try next_seed_ranges.append(overlap_range);
                        remove = true;
                    }
                    if (potential_seed_range.backlap(&_conversion.source_range)) |backlap_range| {
                        try potential_seed_ranges.append(backlap_range);
                        remove = true;
                    }
                    if (potential_seed_range.frontlap(&_conversion.source_range)) |frontlap_range| {
                        try potential_seed_ranges.append(frontlap_range);
                        remove = true;
                    }
                    if (remove) {
                        _ = potential_seed_ranges.orderedRemove(i);
                        i -= 1;
                    }
                }
                if (seed_range.overlap(&_conversion.source_range)) |overlap_range| {
                    try next_seed_ranges.append(overlap_range);
                }
                if (seed_range.backlap(&_conversion.source_range)) |backlap_range| {
                    try potential_seed_ranges.append(backlap_range);
                }
                if (seed_range.frontlap(&_conversion.source_range)) |frontlap_range| {
                    try potential_seed_ranges.append(frontlap_range);
                }
            }
        }
        std.debug.print("next_seed_ranges:\n", .{});
        for (next_seed_ranges.items) |range_| std.debug.print("\t{!}\n", .{range_});
        seed_ranges = next_seed_ranges;
    }

    for (seed_ranges.items) |seed_range| {
        if (seed_range.start < min) {
            min = seed_range.start;
        }
    }

    std.debug.print("Day " ++ day ++ " -> {d}\n", .{min});
}
