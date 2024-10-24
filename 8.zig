const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    const pa = std.heap.page_allocator;
    var steps: usize = 0;
    var pattern = std.ArrayList(bool).init(pa);
    var map = std.AutoHashMap([3]u8, [2][3]u8).init(pa);

    var lines = std.mem.splitScalar(u8, input, '\n');

    for (lines.next().?) |c| try pattern.append(c == 'R');

    _ = lines.next();
    var current: [3]u8 = "AAA".*;

    while (lines.next()) |line| {
        if (line.len > 0) {
            switch (line[0]) {
                'A'...'Z' => try map.put(line[0..3].*, .{ line[7..10].*, line[12..15].* }),
                else => {},
            }
        }
    }

    while (!std.mem.eql(u8, &current, "ZZZ")) : (steps += 1) {
        const go_right = pattern.items[steps % pattern.items.len];
        current = if (go_right) map.get(current).?[1] else map.get(current).?[0];
    }

    print("Day " ++ day ++ " >> {}\n", .{steps});
}
