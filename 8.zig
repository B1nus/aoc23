const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    const pa = std.heap.page_allocator;
    var steps: usize = 1;
    var pattern = std.ArrayList(bool).init(pa);
    var map = std.AutoHashMap([3]u8, [2][3]u8).init(pa);

    var lines = std.mem.splitScalar(u8, input, '\n');

    for (lines.next().?) |c| try pattern.append(c == 'R');

    _ = lines.next();
    var ghosts = std.ArrayList([3]u8).init(pa);

    while (lines.next()) |line| {
        if (line.len > 0) {
            if (line[2] == 'A') try ghosts.append(line[0..3].*);
            try map.put(line[0..3].*, .{ line[7..10].*, line[12..15].* });
        }
    }

    for (ghosts.items) |*ghost| {
        var cycle: usize = 0;
        while (ghost.*[2] != 'Z') : (cycle += 1) {
            const go_right = pattern.items[cycle % pattern.items.len];
            const index: usize = if (go_right) 1 else 0;
            ghost.* = map.get(ghost.*).?[index];
        }
        steps *= cycle / euclidean(cycle, steps);
    }

    print("Day " ++ day ++ " >> {}\n", .{steps});
}

pub fn euclidean(a: usize, b: usize) usize {
    var new_a: usize = a;
    var new_b: usize = b;
    while (new_b != 0) {
        const temp = new_a;
        new_a = new_b;
        new_b = temp % new_b;
    }
    return new_a;
}

test "Euklid" {
    try std.testing.expect(euclidean(6, 2) == 2);
}
