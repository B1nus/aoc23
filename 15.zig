const std = @import("std");
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

pub fn main() !void {
    var strings = std.mem.splitScalar(u8, @embedFile("15.txt"), ',');

    var boxes = std.ArrayList(Box).init(page_allocator);
    while (strings.next()) |string_| {
        const string = if (string_[string_.len - 1] == '\n') string_[0 .. string_.len - 1] else string_;
        const split_pos = std.mem.indexOfAny(u8, string, "-=").?;
        const label = string[0..split_pos];
        const box = hash(label);
        switch (string[split_pos]) {
            '-' => if (find(boxes, box, label)) |index| {
                _ = boxes.orderedRemove(index);
            },
            '=' => {
                const value = string[split_pos + 1] - '0';
                if (find(boxes, box, label)) |index| {
                    boxes.items[index].value = value;
                } else {
                    const element = Box{ .box = box, .label = label, .value = value };
                    if (find(boxes, box, "")) |insert_index| {
                        try boxes.insert(insert_index + 1, element);
                    } else {
                        try boxes.append(element);
                    }
                }
            },
            else => {
                unreachable;
            },
        }
        // var i: usize = 0;
        // print("\nAfter \"{s}\":\n", .{string});
        // while (i < boxes.items.len) {
        //     const box_num = boxes.items[i].box;
        //     print("box {d}: ", .{box_num});
        //     while (i < boxes.items.len and boxes.items[i].box == box_num) : (i += 1) {
        //         print("[{s} {d}] ", .{ boxes.items[i].label, boxes.items[i].value });
        //     }
        //     print("\n", .{});
        // }
    }

    var sum: usize = 0;
    var index: usize = 0;
    var cur_box: usize = 0;
    for (boxes.items) |box| {
        if (cur_box != box.box) {
            index = 0;
        }

        sum += (box.box + 1) * (index + 1) * box.value;

        index += 1;
        cur_box = box.box;
    }

    print("Day 15 >> {d}\n", .{sum});
}

const Box = struct {
    box: usize,
    label: []const u8,
    value: usize,
};

pub fn find(boxes: std.ArrayList(Box), box: usize, label: []const u8) ?usize {
    for (0..boxes.items.len) |i| {
        const index = boxes.items.len - 1 - i;
        const b = boxes.items[index];
        if (b.box == box and (label.len == 0 or std.mem.eql(u8, b.label, label))) {
            return index;
        }
    }
    return null;
}

pub fn hash(string: []const u8) usize {
    var val: usize = 0;
    for (string) |c| {
        if (c != '\n') {
            val += c;
            val *= 17;
            val = val % 256;
        }
    }
    return val;
}
