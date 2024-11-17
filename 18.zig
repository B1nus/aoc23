const std = @import("std");

pub fn main() !void {
    var x: isize = 0;
    var y: isize = 0;

    var min_x: isize = 0xFFFFFFFF;
    var max_x: isize = 0;
    var min_y: isize = 0xFFFFFFFF;
    var max_y: isize = 0;

    var lines = std.mem.splitScalar(u8, @embedFile("18.txt"), '\n');
    while (lines.next()) |line| {
        if (line.len > 0) {
            var line_parts = std.mem.splitScalar(u8, line, ' ');
            const direction = line_parts.next().?[0];
            const steps = @as(isize, @intCast(try std.fmt.parseInt(usize, line_parts.next().?, 10)));
            // const color = try std.fmt.parseInt(u24, line_parts.next().?[2..8], 16);

            switch (direction) {
                'U' => y -= steps,
                'D' => y += steps,
                'L' => x -= steps,
                'R' => x += steps,
                else => unreachable,
            }

            min_x = @min(min_x, x);
            max_x = @max(max_x, x);
            min_y = @min(min_y, y);
            max_y = @max(max_y, y);
        }
    }

    const width = @abs(max_x - min_x) + 1;
    const height = @abs(max_y - min_y) + 1;

    var visited = try std.heap.page_allocator.alloc(bool, width * height);
    @memset(visited, false);

    var x_: usize = @abs(min_x);
    var y_: usize = @abs(min_y);
    visited[x_ + y_ * width] = true;
    var lines2 = std.mem.splitScalar(u8, @embedFile("18.txt"), '\n');
    while (lines2.next()) |line| {
        if (line.len > 0) {
            var line_parts = std.mem.splitScalar(u8, line, ' ');
            const direction = line_parts.next().?[0];
            const steps = try std.fmt.parseInt(usize, line_parts.next().?, 10);

            for (0..steps) |_| {
                switch (direction) {
                    'U' => y_ -= 1,
                    'D' => y_ += 1,
                    'L' => x_ -= 1,
                    'R' => x_ += 1,
                    else => unreachable,
                }
                visited[x_ + y_ * width] = true;
            }
        }
    }

    var to_check = std.ArrayList(usize).init(std.heap.page_allocator);
    try to_check.append(width / 2 + height / 2 * width);
    while (to_check.items.len > 0) {
        var new = std.ArrayList(usize).init(std.heap.page_allocator);
        for (to_check.items) |id| {
            if (!visited[id]) {
                visited[id] = true;
                try new.append(id + 1);
                try new.append(id - 1);
                try new.append(id - width);
                try new.append(id + width);
            }
        }
        to_check.clearRetainingCapacity();
        try to_check.appendSlice(new.items);
        new.clearAndFree();
    }

    var sum: usize = 0;
    for (0..height) |h| {
        for (0..width) |w| {
            if (visited[w + h * width]) {
                // std.debug.print("#", .{});
                sum += 1;
            } else {
                // std.debug.print(".", .{});
            }
        }
        // std.debug.print("\n", .{});
    }

    std.debug.print("Day 18 >> {d}\n", .{sum});
}
