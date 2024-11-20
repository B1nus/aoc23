const std = @import("std");

pub fn main() !void {
    // Please note that I cheated again. I took help from a video on the problem from @programmingproblems on youtube. They have great videos on the problems.
    // var prod: usize = 1;
    var modules, const outputs, const inputs, var memory = try parse_input(@embedFile("20.txt"));
    _ = try button_presses(&modules, outputs, inputs, &memory, "", false);
    // for (try find_parent_parents(inputs, "rx")) |in| {
    //     var modules, _, _, var memory = try parse_input(@embedFile("20.txt"));
    //     defer modules.deinit();
    //     defer memory.deinit();
    //     const cycle = try button_presses(&modules, outputs, inputs, &memory, in, false);
    //     std.debug.print("{s} {d} \n\n", .{ in, cycle });
    //     prod *= lcm(prod, cycle);
    // }
    // std.debug.print("Day 20 >> {d}\n", .{prod});
}

pub fn find_parent_parents(inputs: std.StringHashMap([][]const u8), label: []const u8) ![][]const u8 {
    const parent = inputs.get(label).?[0];
    const parent_parents = inputs.get(parent).?;
    var parent_parent_parents = std.ArrayList([]const u8).init(std.heap.page_allocator);
    for (parent_parents) |parent_parent| {
        try parent_parent_parents.appendSlice(inputs.get(parent_parent).?);
    }
    return parent_parent_parents.items;
}

pub fn parse_input(input: []const u8) !struct { std.StringHashMap(Module), std.StringHashMap([][]const u8), std.StringHashMap([][]const u8), std.StringHashMap(?bool) } {
    var modules = std.StringHashMap(Module).init(std.heap.page_allocator);
    var outputs = std.StringHashMap([][]const u8).init(std.heap.page_allocator);
    var inputs = std.StringHashMap([][]const u8).init(std.heap.page_allocator);
    var memory = std.StringHashMap(?bool).init(std.heap.page_allocator);

    try modules.put("button", Module.button);
    var slice: [][]const u8 = try std.heap.page_allocator.alloc([]const u8, 1);
    slice[0] = "button";
    try inputs.put("broadcaster", slice);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len > 0) {
            var iter = std.mem.splitSequence(u8, line, " -> ");
            const label = switch (line[0]) {
                'b' => iter.next().?,
                else => iter.next().?[1..],
            };
            const out_count = std.mem.count(u8, line, ",") + 1;
            var out_iter = std.mem.splitSequence(u8, iter.next().?, ", ");
            var labels = try std.heap.page_allocator.alloc([]const u8, out_count);
            for (0..out_count) |i| {
                labels[i] = out_iter.next().?;
                if (inputs.getPtr(labels[i])) |ptr| {
                    for (ptr.*) |*s| {
                        if (s.len == 0) {
                            s.* = label;
                            break;
                        }
                    }
                } else {
                    var s = try std.heap.page_allocator.alloc(u8, labels[i].len + 1);
                    std.mem.copyForwards(u8, s[1..], labels[i]);
                    s[0] = ' ';
                    const input_count = std.mem.count(u8, input, s);
                    var input_labels = try std.heap.page_allocator.alloc([]const u8, input_count);
                    input_labels[0] = label;
                    for (input_labels[1..]) |*lab| {
                        lab.* = "";
                    }
                    try inputs.put(labels[i], input_labels);
                }
            }
            const module = switch (line[0]) {
                '%' => Module{ .flip_flop = false },
                '&' => Module{ .conjunction = 0 },
                'b' => Module.broadcaster,
                else => unreachable,
            };
            try modules.put(label, module);
            try outputs.put(label, labels);
            try memory.put(label, null);
        }
    }

    return .{ modules, outputs, inputs, memory };
}

pub fn button_presses(modules: *std.StringHashMap(Module), outputs: std.StringHashMap([][]const u8), inputs: std.StringHashMap([][]const u8), memory: *std.StringHashMap(?bool), label: []const u8, pulse: bool) !usize {
    var count: usize = 0;
    var low_pulses: usize = 0;
    var high_pulses: usize = 0;
    while (count < 1000) : (count += 1) {
        try press_button(modules, outputs, inputs, memory, &high_pulses, &low_pulses);
    }
    std.debug.print("{d}\n", .{low_pulses * high_pulses});
    _ = label;
    _ = pulse;
    // var it = memory.keyIterator();
    // while (it.next()) |l| {
    //     std.debug.print("{s} {any}\n", .{ l.*, memory.get(l.*).? });
    // }
    return count;
}

pub fn press_button(modules: *std.StringHashMap(Module), outputs: std.StringHashMap([][]const u8), inputs: std.StringHashMap([][]const u8), memory: *std.StringHashMap(?bool), high_pulses: *usize, low_pulses: *usize) !void {
    var pulses = std.ArrayList(Pulse).init(std.heap.page_allocator);
    defer pulses.deinit();
    try pulses.append(Pulse{ .from = "button", .to = "broadcaster", .high = false });
    while (pulses.items.len > 0) {
        var new_pulses = std.ArrayList(Pulse).init(std.heap.page_allocator);
        defer new_pulses.deinit();
        for (pulses.items) |pulse| {
            if (pulse.high) high_pulses.* += 1;
            if (!pulse.high) low_pulses.* += 1;
            if (modules.getPtr(pulse.to)) |mod| {
                switch (mod.*) {
                    .button => unreachable,
                    .broadcaster => {
                        for (outputs.get(pulse.to).?) |out| {
                            try new_pulses.append(Pulse{ .from = pulse.to, .to = out, .high = pulse.high });
                        }
                        try memory.put(pulse.to, false);
                    },
                    .flip_flop => |*on| {
                        if (!pulse.high) {
                            on.* = !on.*;
                            for (outputs.get(pulse.to).?) |out| {
                                try new_pulses.append(Pulse{ .from = pulse.to, .to = out, .high = on.* });
                            }
                            try memory.put(pulse.to, on.*);
                        }
                    },
                    .conjunction => |_| {
                        var all_high = true;
                        for (inputs.get(pulse.to).?) |in| {
                            if (memory.get(in).?) |mem| {
                                if (!mem) {
                                    all_high = false;
                                    break;
                                }
                            }
                        }

                        for (outputs.get(pulse.to).?) |out| {
                            try new_pulses.append(Pulse{ .from = pulse.to, .to = out, .high = !all_high });
                        }
                        try memory.put(pulse.to, !all_high);
                    },
                }
            }
        }

        pulses.clearAndFree();
        try pulses.appendSlice(new_pulses.items);
    }
}

// Least common multiple
pub fn lcm(a: usize, b: usize) usize {
    return a * b / std.math.gcd(a, b);
}

const Pulse = struct {
    from: []const u8,
    to: []const u8,
    high: bool,
};

const Module = union(enum) {
    button,
    broadcaster,
    conjunction: usize, // Counting the amount of high in pulses.
    flip_flop: bool, // On or off
};
