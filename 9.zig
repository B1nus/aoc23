const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    const pa = std.heap.page_allocator;

    var sum: isize = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len > 0) {
            var numbers_iter = std.mem.splitScalar(u8, line, ' ');
            var numbers = std.ArrayList(isize).init(pa);
            while (numbers_iter.next()) |number_str| {
                if (number_str.len > 0) {
                    try numbers.append(try std.fmt.parseInt(isize, number_str, 10));
                }
            }
            const prediction = predict(numbers.items, pa);
            sum += prediction;
        }
    }

    print("Day " ++ day ++ " >> {d}\n", .{sum});
}

pub fn predict(numbers: []isize, allocator: std.mem.Allocator) isize {
    var last_nums = std.ArrayList(isize).init(allocator);
    var cur_nums = std.ArrayList(isize).init(allocator);
    defer last_nums.deinit();
    defer cur_nums.deinit();
    cur_nums.appendSlice(numbers) catch {};
    var is_zero = false;

    while (!is_zero) {
        is_zero = true;
        last_nums.append(cur_nums.getLast()) catch {};
        for (0..cur_nums.items.len - 1) |i| {
            cur_nums.items[i] = cur_nums.items[i + 1] - cur_nums.items[i];
            if (cur_nums.items[i] != 0) {
                is_zero = false;
            }
        }
        _ = cur_nums.pop();
    }

    var prediction: isize = 0;
    for (0..last_nums.items.len) |_| {
        prediction += last_nums.pop();
    }

    return prediction;
}

const expect = std.testing.expect;
const alloc = std.testing.allocator;

test "predict" {
    try expect(predict(&[_]isize{ 10, 13, 16 }, alloc) == 19);
    try expect(predict(&[_]isize{ 10, 13, 16, 21, 30, 45 }, alloc) == 68);
    try expect(predict(&[_]isize{ 1, 3, 6, 10, 15, 21 }, alloc) == 28);
}
