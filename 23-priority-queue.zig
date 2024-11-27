const std = @import("std");

fn priority(_: void, a: std.ArrayList(usize), b: std.ArrayList(usize)) std.math.Order {
    const alast = b.getLast();
    const blast = a.getLast();
    if (alast < blast) {
        return std.math.Order.lt;
    }
    if (alast > blast) {
        return std.math.Order.gt;
    } else {
        return std.math.Order.eq;
    }
}

pub fn main() !void {
    const grid, const width = try parse_grid(@embedFile("23.txt"), std.heap.page_allocator);
    var paths = std.PriorityQueue(std.ArrayList(usize), void, priority).init(std.heap.page_allocator, void{});
    var maxes = std.AutoHashMap(usize, usize).init(std.heap.page_allocator);
    try paths.add(std.ArrayList(usize).init(std.heap.page_allocator));
    try paths.items[0].append(1);

    var max: usize = 0;
    while (paths.removeOrNull()) |path| {
        if (maxes.get(path.getLast())) |cmax| {
            if (cmax >= path.items.len - 1) {
                continue;
            } else if (path.items.len - 1 > cmax) {
                try maxes.put(path.getLast(), path.items.len - 1);
            }
        }

        var new_positions = std.ArrayList(usize).init(std.heap.page_allocator);
        defer new_positions.deinit();
        defer path.deinit();

        if (path.getLast() == grid.len - 2) {
            if (path.items.len - 1 > max) {
                max = path.items.len - 1;
                std.debug.print("\t\x1b[1mmax:{d}\x1b[0m\n", .{max});
            } else {
                std.debug.print("paths:{d}\n", .{paths.items.len});
            }
            // for (0..grid.len / width) |y| {
            //     for (0..width) |x| {
            //         const i = x + y * width;
            //         if (std.mem.count(usize, path.items, &.{i}) == 1) {
            //             std.debug.print("*", .{});
            //         } else {
            //             std.debug.print("{c}", .{grid[i]});
            //         }
            //     }
            //     std.debug.print("\n", .{});
            // }
            continue;
        }

        if (try valid_next_pos(grid, path.items, -1)) |pos| {
            try new_positions.append(pos);
        }
        if (try valid_next_pos(grid, path.items, 1)) |pos| {
            try new_positions.append(pos);
        }
        if (try valid_next_pos(grid, path.items, -@as(isize, @intCast(width)))) |pos| {
            try new_positions.append(pos);
        }
        if (try valid_next_pos(grid, path.items, @as(isize, @intCast(width)))) |pos| {
            try new_positions.append(pos);
        }

        for (new_positions.items) |new| {
            var new_path = try path.clone();
            try new_path.append(new);
            try paths.add(new_path);
        }
    }

    std.debug.print("{d}\n", .{max});
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
