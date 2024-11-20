// I cheated btw. If anyone was wondering. https://www.youtube.com/watch?v=VaKpsB9n6rk
const std = @import("std");

pub fn main() !void {
    var prod: u128 = 1;
    var wires = try Wires.new(@embedFile("20.txt"), std.heap.page_allocator);
    defer wires.deinit();
    for (try wires.get_parents("rx", 3)) |in| {
        wires.reset();
        while (wires.cycle.get(in) == null) {
            try wires.press_button();
        }
        // std.debug.print("{s} {d}\n", .{ in, wires.cycle.get(in).? });
        prod = lcm(prod, wires.cycle.get(in).?);
    }

    std.debug.print("{d}\n", .{prod});
}

pub fn lcm(a: u128, b: u128) u128 {
    return a * b / std.math.gcd(a, b);
}

const Wires = struct {
    module_type: std.StringHashMap(Module),
    inputs: std.StringHashMap(std.ArrayList([]const u8)),
    outputs: std.StringHashMap(std.ArrayList([]const u8)),
    memory: std.StringHashMap(PulseType),
    cycle: std.StringHashMap(usize),
    queue: Queue,
    presses: usize,

    pub fn new(input: []const u8, allocator: std.mem.Allocator) !@This() {
        const queue = Queue.new(allocator);
        var memory = std.StringHashMap(PulseType).init(allocator);
        var module_type = std.StringHashMap(Module).init(allocator);
        var inputs = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
        var outputs = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
        const cycle = std.StringHashMap(usize).init(allocator);

        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |line| {
            if (line.len == 0) continue;

            var arrow_split = std.mem.splitSequence(u8, line, " -> ");
            const label, const module_type_ = switch (line[0]) {
                'b' => .{ arrow_split.next().?, Module.Broadcaster },
                '%' => .{ arrow_split.next().?[1..], Module.FlipFlop },
                '&' => .{ arrow_split.next().?[1..], Module.Conjunction },
                else => .{ arrow_split.next().?, Module.Unknown },
            };

            try outputs.put(label, std.ArrayList([]const u8).init(allocator));
            var outputs_ = std.mem.splitSequence(u8, arrow_split.next().?, ", ");
            while (outputs_.next()) |output| {
                try outputs.getPtr(label).?.append(output);

                // For modules not listed, such as rx
                if (module_type.get(output) == null) {
                    try module_type.put(output, Module.Unknown);
                    try outputs.put(output, std.ArrayList([]const u8).init(allocator));
                }

                // Adding as input to the receiving end
                if (inputs.getPtr(output)) |in| {
                    try in.append(label);
                } else {
                    try inputs.put(output, std.ArrayList([]const u8).init(allocator));
                    try inputs.getPtr(output).?.append(label);
                }
            }

            try module_type.put(label, module_type_);
            try memory.put(label, low);

            // If it has no outputs/inputs, add an empty list. For simplicities sake
            if (outputs.get(label) == null) try outputs.put(label, std.ArrayList([]const u8).init(allocator));
            if (inputs.get(label) == null) try inputs.put(label, std.ArrayList([]const u8).init(allocator));
        }

        return @This(){ .module_type = module_type, .inputs = inputs, .outputs = outputs, .memory = memory, .cycle = cycle, .queue = queue, .presses = 0 };
    }

    pub fn get_parents(self: *@This(), child: []const u8, depth: usize) ![][]const u8 {
        var children = std.ArrayList([]const u8).init(self.module_type.allocator);
        var parents = std.ArrayList([]const u8).init(self.module_type.allocator);
        defer children.deinit();

        try children.append(child);

        for (0..depth) |_| {
            parents.clearAndFree();
            while (children.popOrNull()) |c| {
                try parents.appendSlice(self.inputs.get(c).?.items);
            }
            children.clearAndFree();
            try children.appendSlice(parents.items);
        }

        return parents.items;
    }

    pub fn reset(self: *@This()) void {
        self.queue.clear();
        self.cycle.clearAndFree();
        var it = self.memory.keyIterator();
        while (it.next()) |label| {
            self.memory.getPtr(label.*).?.* = low;
        }
        self.presses = 0;
    }

    pub fn deinit(self: *@This()) void {
        self.module_type.deinit();
        self.cycle.deinit();
        self.inputs.deinit();
        self.outputs.deinit();
        self.memory.deinit();
        self.queue.deinit();
    }

    pub fn press_button(self: *@This()) !void {
        try self.queue.list.append(Pulse{ .to = "broadcaster", .type = low });
        self.presses += 1;
        while (self.queue.items().len != 0) {
            for (self.queue.items()) |pulse| {
                // if (pulse.type == high) std.debug.print("-high-> {s}\n", .{pulse.to}) else std.debug.print("-low-> {s}\n", .{pulse.to});
                try self.process_pulse(pulse);
            }
            try self.queue.update();
        }
    }

    pub fn response(self: *@This(), pulse: Pulse) !?PulseType {
        switch (self.module_type.get(pulse.to).?) {
            .Broadcaster => return pulse.type,
            .FlipFlop => {
                if (pulse.type == low) {
                    return self.memory.getPtr(pulse.to).?.*.opposite();
                } else {
                    return null;
                }
            },
            .Conjunction => {
                for (self.inputs.get(pulse.to).?.items) |in| {
                    if (self.memory.get(in).? == low) {
                        return high;
                    }
                }

                try self.cycle.put(pulse.to, self.presses);
                return low;
            },
            .Unknown => return null,
        }
    }

    pub fn process_pulse(self: *@This(), pulse: Pulse) !void {
        if (try self.response(pulse)) |pulse_type| {
            self.memory.getPtr(pulse.to).?.* = pulse_type;

            for (self.outputs.get(pulse.to).?.items) |output| {
                try self.queue.append(Pulse{ .to = output, .type = pulse_type });
            }
        }
    }

    pub fn print(self: @This()) !void {
        var labels = self.module_type.keyIterator();

        while (labels.next()) |label_| {
            const label = label_.*;
            std.debug.print("{s} \x1b[1m-> {s} ->\x1b[0m {s}\n", .{
                try std.mem.join(self.module_type.allocator, ", ", self.inputs.get(label).?.items),
                label,
                try std.mem.join(self.module_type.allocator, ", ", self.outputs.get(label).?.items),
            });
        }
    }
};

const Queue = struct {
    list: std.ArrayList(Pulse),
    next: std.ArrayList(Pulse),

    pub fn new(allocator: std.mem.Allocator) @This() {
        return @This(){
            .list = std.ArrayList(Pulse).init(allocator),
            .next = std.ArrayList(Pulse).init(allocator),
        };
    }

    // Add pulses to send, use update for this to take effect
    pub fn append(self: *@This(), pulse: Pulse) !void {
        try self.next.append(pulse);
    }

    // Add the new pulses and remove the old ones.
    pub fn update(self: *@This()) !void {
        self.list = try self.next.clone();
        self.next.clearAndFree();
    }

    pub fn items(self: @This()) []Pulse {
        return self.list.items;
    }

    pub fn clear(self: *@This()) void {
        self.list.clearAndFree();
        self.next.clearAndFree();
    }

    pub fn deinit(self: *@This()) void {
        self.list.deinit();
        self.next.deinit();
    }
};

const Pulse = struct {
    to: []const u8,
    type: PulseType,
};

const high = PulseType.high;
const low = PulseType.low;
const PulseType = enum {
    low,
    high,

    pub fn opposite(self: @This()) @This() {
        return switch (self) {
            .low => PulseType.high,
            .high => PulseType.low,
        };
    }
};

const Module = enum {
    Unknown,
    Broadcaster,
    FlipFlop,
    Conjunction,
};
