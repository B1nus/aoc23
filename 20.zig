const std = @import("std");
const input = @embedFile("20.txt");

pub fn main() !void {
    var modules = std.StringHashMap(Module).init(std.heap.page_allocator);
    var outputs = std.StringHashMap([][]const u8).init(std.heap.page_allocator);
    var inputs = std.StringHashMap([][]const u8).init(std.heap.page_allocator);
    var memory = std.StringHashMap(bool).init(std.heap.page_allocator);

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
            try memory.put(label, false);
        }
    }

    // var o_iter = outputs.iterator();
    // while (o_iter.next()) |entry| {
    //     const label = entry.key_ptr.*;
    //     const outputs_ = entry.value_ptr.*;
    //     const inputs_ = inputs.get(label).?;
    //     std.debug.print("{s}", .{inputs_[0]});
    //     for (inputs_[1..]) |input_l| {
    //         std.debug.print(", {s}", .{input_l});
    //     }
    //     std.debug.print(" -> {s} -> {s}", .{ label, outputs_[0] });
    //     for (outputs_[1..]) |out| {
    //         std.debug.print(", {s}", .{out});
    //     }
    //     std.debug.print("\n", .{});
    // }
    // std.debug.print("\nPulses:\n", .{});

    var presses: usize = 0;
    var update: usize = 0;
    outer: while (true) {
        var pulses = std.ArrayList(Pulse).init(std.heap.page_allocator);
        defer pulses.deinit();
        try pulses.append(Pulse{ .from = "button", .to = "broadcaster", .high = false });
        presses += 1;
        while (pulses.items.len > 0) {
            var new_pulses = std.ArrayList(Pulse).init(std.heap.page_allocator);
            defer new_pulses.deinit();
            for (pulses.items) |pulse| {
                if (pulse.high) {
                    // std.debug.print("{s} -high-> {s}\n", .{ pulse.from, pulse.to });
                } else {
                    if (pulse.to[0] == 'r' and pulse.to[1] == 'x') {
                        break :outer;
                    }
                    // std.debug.print("{s} -low-> {s}\n", .{ pulse.from, pulse.to });
                }
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
                                if (!memory.get(in).?) {
                                    all_high = false;
                                    break;
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
        update += 1;
        if (update == 10000) {
            update = 0;
            std.debug.print("{d} cl:{}, rp:{}, lb:{}, nj:{}\n", .{ presses, memory.get("cl").?, memory.get("rp").?, memory.get("lb").?, memory.get("nj").? });
        }
    }
    std.debug.print("Day 20 >> {d}\n", .{presses});
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
