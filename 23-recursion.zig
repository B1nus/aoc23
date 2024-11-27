const std = @import("std");

pub fn main() !void {
    const grid, const width = try parse_grid(@embedFile("23.txt"), std.heap.page_allocator);
    var maxes = std.AutoHashMap([2]usize, usize).init(std.heap.page_allocator);
    try maxes.put(.{ grid.len - 2 - width, grid.len - 2 }, 1);
    var path = std.ArrayList(usize).init(std.heap.page_allocator);
    try path.append(1);

    const max = (try max_path(grid, width, &maxes, path)).?;

    std.debug.print("{d}\n", .{max});
}

pub fn max_path(grid: []const u8, width: usize, maxes: *std.AutoHashMap([2]usize, usize), path: std.ArrayList(usize)) !?usize {
    if (path.items.len >= 2) {
        if (maxes.get(.{ path.items[path.items.len - 2], path.items[path.items.len - 1] })) |cached_max| {
            return cached_max;
        } else if (path.getLast() > 19737) {
            std.debug.print("looking for {d},{d}\n", .{ path.items[path.items.len - 2], path.items[path.items.len - 1] });
        }
    }

    var new_positions = std.ArrayList(usize).init(std.heap.page_allocator);
    defer new_positions.deinit();
    for ([_]isize{
        -1,
        1,
        @intCast(width),
        -@as(isize, @intCast(width)),
    }) |delta| {
        if (try valid_next_pos(grid, path.items, delta)) |pos| {
            try new_positions.append(pos);
        }
    }

    // std.debug.print("new_positions:{any} {}\n", .{ new_positions.items, path.getLast() == grid.len - 2 });
    if (new_positions.items.len == 0) {
        return null;
    }
    var max: usize = 0;
    for (new_positions.items) |new| {
        var new_path = try path.clone();
        try new_path.append(new);
        if (try max_path(grid, width, maxes, new_path)) |max_| {
            max = @max(max, max_);
        }
    }

    if (path.items.len >= 2) {
        try maxes.put(.{ path.items[path.items.len - 2], path.items[path.items.len - 1] }, max + 1);
    }

    return max + 1;
}

pub fn valid_next_pos(grid: []const u8, path: []usize, delta: isize) !?usize {
    const cur_pos: isize = @intCast(path[path.len - 1]);
    if ((cur_pos == 1 and delta < 0) or @as(usize, @intCast(cur_pos + delta)) > grid.len) {
        return null;
    }

    const next = @as(usize, @intCast(cur_pos + delta));
    if (std.mem.count(usize, path, &.{next}) == 1) {
        return null;
    } else if (grid[next] != '#') {
        return next;
    } else {
        return null;
    }
}

pub fn parse_grid(input: []const u8, allocator: std.mem.Allocator) !struct { []const u8, usize } {
    var lines = std.mem.splitScalar(u8, input, '\n');
    const width = lines.peek().?.len;
    var characters = std.ArrayList(u8).init(allocator);
    while (lines.next()) |line| {
        try characters.appendSlice(line);
    }
    return .{ characters.items, width };
}
