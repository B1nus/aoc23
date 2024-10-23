const std = @import("std");
const stdout = std.io.getStdOut().writer();
var buffer: [1000]u8 = undefined;

const range = struct {
    start: usize,
    length: usize,

    fn from_start_end(start: usize, _end: usize) ?range {
        if (start > _end) {
            return null;
        } else {
            return range{ .start = start, .length = _end - start + 1 };
        }
    }

    pub fn overlap_and_nonlap(self: range, other: *const range, allocator: std.mem.Allocator) !struct { overlap: std.ArrayList(range), nonlap: std.ArrayList(range) } {
        var lap = std.ArrayList(range).init(allocator);
        var nonlap = std.ArrayList(range).init(allocator);

        if (self.overlap(other)) |r| {
            try lap.append(r);
        }
        if (self.backlap(other)) |r| {
            try nonlap.append(r);
        }
        if (self.frontlap(other)) |r| {
            try nonlap.append(r);
        }

        return .{ .overlap = lap, .nonlap = nonlap };
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
            return range.from_start_end(self.start, @min(other.start - 1, self.end()));
        } else {
            return null;
        }
    }

    fn frontlap(self: range, other: *const range) ?range {
        if (self.end() > other.end()) {
            return range.from_start_end(@max(other.end() + 1, self.start), self.end());
        } else {
            return null;
        }
    }

    fn end(self: range) usize {
        return self.start + self.length - 1;
    }

    fn dbg(self: range, comptime prepend: []const u8, comptime append: []const u8) void {
        std.debug.print(prepend ++ "[{d}..{d}]" ++ append, .{ self.start, self.end() });
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
            if (line.len == 0 or line[0] < 48 or line[0] > 57) break;
            var numbers = std.mem.splitScalar(u8, line, ' ');

            const destination_start = try std.fmt.parseInt(usize, numbers.next().?, 10);
            const source_start = try std.fmt.parseInt(usize, numbers.next().?, 10);
            const length = try std.fmt.parseInt(usize, numbers.next().?, 10);

            const conversion_ = conversion{
                .source_range = range{
                    .start = source_start,
                    .length = length,
                },
                .destination_start = destination_start,
            };

            try conversions.append(conversion_);
        }

        return conversions;
    }
};

pub fn convert_ranges(ranges: *std.ArrayList(range), conversions: *const []conversion, allocator: std.mem.Allocator) !std.ArrayList(range) {
    var output = std.ArrayList(range).init(allocator);

    for (conversions.*) |converter| {
        const seeds = try ranges.toOwnedSlice();
        ranges.clearAndFree();

        for (seeds) |seed| {
            const overlap_nonlap = try seed.overlap_and_nonlap(&converter.source_range, allocator);

            try ranges.appendSlice(overlap_nonlap.nonlap.items);

            if (overlap_nonlap.overlap.capacity > 0) {
                var overlap_range = overlap_nonlap.overlap.items[0];
                converter.convert_range(&overlap_range);
                try output.append(overlap_range);
            }
        }
    }

    return output;
}

pub fn main() !void {
    var fba = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = fba.allocator();
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    var min: usize = undefined;

    var paragraphs = std.mem.splitSequence(u8, input, ":\n");

    // Skip first paragraph with the intial seed ranges
    _ = paragraphs.next();

    var seed_ranges = std.ArrayList(range).init(allocator);
    defer seed_ranges.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    const seed_ranges_line = lines.next().?[7..];
    var seed_iter = std.mem.splitScalar(u8, seed_ranges_line, ' ');
    while (seed_iter.next()) |seed| {
        const start = try std.fmt.parseInt(usize, seed, 10);
        const length = try std.fmt.parseInt(usize, seed_iter.next().?, 10);
        try seed_ranges.append(range{ .start = start, .length = length });
    }

    while (paragraphs.next()) |paragraph| {
        const conversions = try conversion.parse_paragraph(paragraph, allocator);
        defer conversions.deinit();

        const new_seeds = try convert_ranges(&seed_ranges, &conversions.items, allocator);
        try seed_ranges.appendSlice(new_seeds.items);
    }

    for (seed_ranges.items) |seed_range| {
        if (seed_range.start < min) {
            min = seed_range.start;
        }
    }

    std.debug.print("Day " ++ day ++ " -> {d}\n", .{min});
}

const expect = std.testing.expect;

test "total backlap" {
    const self = range{ .start = 5, .length = 5 };
    const other = range{ .start = 12, .length = 2 };

    try expect(self.backlap(&other).?.start == self.start);
    try expect(self.backlap(&other).?.length == self.length);
}

test "total frontlap" {
    const self = range{ .start = 12, .length = 2 };
    const other = range{ .start = 5, .length = 5 };

    try expect(self.frontlap(&other).?.start == self.start);
    try expect(self.frontlap(&other).?.length == self.length);
}

test "overlap and backlap" {
    const self = range{ .start = 0, .length = 5 };
    const other = range{ .start = 2, .length = 4 };
    try expect(self.overlap(&other).?.start == 2);
    try expect(self.overlap(&other).?.length == 3);
    try expect(self.backlap(&other).?.start == 0);
    try expect(self.backlap(&other).?.length == 2);
}

test "all at once" {
    const self = range{ .start = 10, .length = 10 };
    const other = range{ .start = 14, .length = 5 };
    try expect(self.overlap(&other).?.start == 14);
    try expect(self.overlap(&other).?.length == 5);
    try expect(self.backlap(&other).?.start == 10);
    try expect(self.backlap(&other).?.length == 4);
    try expect(self.frontlap(&other).?.start == 19);
    try expect(self.frontlap(&other).?.length == 1);

    const overlap_and_nonlap = try self.overlap_and_nonlap(&other, std.testing.allocator);
    defer overlap_and_nonlap.overlap.deinit();
    defer overlap_and_nonlap.nonlap.deinit();
    try expect(overlap_and_nonlap.overlap.items[0].start == 14);
    try expect(overlap_and_nonlap.nonlap.items.len == 2);
}
