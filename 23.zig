const std = @import("std");

pub fn main() !void {
    const grid, const width = try parse_grid(@embedFile("23.txt"), std.heap.page_allocator);
    var paths = std.ArrayList(std.ArrayList(usize)).init(std.heap.page_allocator);
    try paths.append(std.ArrayList(usize).init(std.heap.page_allocator));
    try paths.items[0].append(1);

    var max: usize = 0;
    var max_path: std.ArrayList(usize) = undefined;
    while (paths.popOrNull()) |path_| {
        var new_positions = std.ArrayList(usize).init(std.heap.page_allocator);
        defer new_positions.deinit();
        var path = path_;

        if (path.getLast() == grid.len - 2) {
            max = @max(path.items.len - 1, max);
            max_path = path;
            continue;
        }

        if (try valid_next_pos(grid, &path, -1, '<')) |pos| {
            try new_positions.append(pos);
        }
        if (try valid_next_pos(grid, &path, 1, '>')) |pos| {
            try new_positions.append(pos);
        }
        if (try valid_next_pos(grid, &path, -@as(isize, @intCast(width)), '^')) |pos| {
            try new_positions.append(pos);
        }
        if (try valid_next_pos(grid, &path, @as(isize, @intCast(width)), 'v')) |pos| {
            try new_positions.append(pos);
        }

        // std.debug.print("\nnew positions:{any}\n", .{new_positions.items});
        for (new_positions.items) |new| {
            var new_path = try path.clone();
            try new_path.append(new);
            try paths.append(new_path);
        }
        // std.debug.print("path count:{d}\n", .{paths.items.len});
    }
    for (0..grid.len / width) |y| {
        for (0..width) |x| {
            const i = y * width + x;
            if (std.mem.count(usize, max_path.items, &.{i}) == 1) {
                std.debug.print("*", .{});
            } else {
                std.debug.print("{c}", .{grid[i]});
            }
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("{d}\n", .{max});
}

pub fn valid_next_pos(grid: []const u8, path: *std.ArrayList(usize), delta: isize, steep_char: u8) !?usize {
    const cur_pos: isize = @intCast(path.getLast());
    if ((cur_pos == 1 and delta < 0) or @as(usize, @intCast(cur_pos + delta)) > grid.len) {
        return null;
    }

    const next = @as(usize, @intCast(cur_pos + delta));
    if (std.mem.count(usize, path.items, &.{next}) == 1) {
        return null;
    } else if (grid[next] == '.' or grid[next] == steep_char) {
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
