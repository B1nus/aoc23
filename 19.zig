const std = @import("std");

pub fn main() !void {
    // Parse Input
    var input = std.mem.splitScalar(u8, @embedFile("19.txt"), '\n');

    var workflows = std.StringHashMap(Workflow).init(std.heap.page_allocator);
    while (input.next()) |workflow_str| {
        if (workflow_str.len > 0) {
            const workflow = try Workflow.parse(workflow_str);
            try workflows.put(workflow.label, workflow);
        } else {
            break;
        }
    }

    var accepted = std.ArrayList(State).init(std.heap.page_allocator);
    var queue = std.ArrayList(State).init(std.heap.page_allocator);
    try queue.append(State.default());

    while (queue.popOrNull()) |state_| {
        if (state_.label[0] == 'R') {
            continue;
        }
        if (state_.label[0] == 'A') {
            try accepted.append(state_);
            continue;
        }

        const workflow = workflows.get(state_.label).?;

        var state = state_;
        for (workflow.rules) |rule_| {
            if (rule_) |rule| {
                if (rule.category == null) {
                    try queue.append(state.change_label(rule.destination));
                    break;
                } else {
                    if (rule.passing_range(state.range(rule.category.?))) |passing| {
                        try queue.append(state.change_range(rule.category.?, passing).change_label(rule.destination));
                    }
                    if (rule.failing_range(state.range(rule.category.?))) |failing| {
                        state = state.change_range(rule.category.?, failing);
                    } else {
                        break;
                    }
                }
            }
        }
    }

    var sum: usize = 0;
    for (accepted.items) |state| {
        // std.debug.print("x: {d}..{d}, m: {d}..{d}, a: {d}..{d}, s: {d}..{d}\n", .{ state.x.min, state.x.max, state.m.min, state.m.max, state.a.min, state.a.max, state.s.min, state.s.max });
        sum += state.x.length() * state.m.length() * state.a.length() * state.s.length();
    }

    std.debug.print("Day 19 >> {d}\n", .{sum});
}

const State = struct {
    x: Range,
    m: Range,
    a: Range,
    s: Range,
    label: []const u8,

    pub fn default() @This() {
        return @This(){ .x = Range.default(), .m = Range.default(), .a = Range.default(), .s = Range.default(), .label = "in" };
    }

    pub fn range(self: @This(), category: Category) Range {
        return switch (category) {
            .Cool => self.x,
            .Musical => self.m,
            .Aerodynamic => self.a,
            .Shiny => self.s,
        };
    }

    pub fn change_range(self: @This(), category: Category, new_range: Range) @This() {
        var new = self;
        switch (category) {
            .Cool => new.x = new_range,
            .Musical => new.m = new_range,
            .Aerodynamic => new.a = new_range,
            .Shiny => new.s = new_range,
        }
        return new;
    }

    pub fn change_label(self: @This(), label: []const u8) @This() {
        var new = self;
        new.label = label;
        return new;
    }
};

const Range = struct {
    min: usize,
    max: usize,

    pub fn default() @This() {
        return @This(){ .min = 1, .max = 4000 };
    }

    pub fn length(self: @This()) usize {
        return self.max - self.min + 1;
    }
};

const Workflow = struct {
    rules: [5:null]?Rule,
    label: []const u8,

    pub fn parse(line: []const u8) !@This() {
        const label_end = std.mem.indexOfScalar(u8, line, '{').?;
        const label = line[0..label_end];

        var rule_iter = std.mem.splitScalar(u8, line[label_end + 1 .. line.len - 1], ',');
        var rules: [5:null]?Rule = .{null} ** 5;
        for (0..5) |i| {
            if (rule_iter.next()) |rule_text| {
                rules[i] = try Rule.parse(rule_text);
            } else {
                break;
            }
        }

        return @This(){ .rules = rules, .label = label };
    }
};

const Category = enum {
    Cool,
    Musical,
    Aerodynamic,
    Shiny,
};

const Criteria = union(enum) {
    less_than: usize,
    more_than: usize,
};

const Destination = union(enum) {
    rejected,
    accepted,
    label: []const u8,
};

const Rule = struct {
    category: ?Category,
    criteria: ?Criteria,
    destination: []const u8,

    pub fn parse(text: []const u8) !Rule {
        if (std.mem.indexOfScalar(u8, text, ':')) |index_of_colon| {
            const category: Category = switch (text[0]) {
                'x' => .Cool,
                'm' => .Musical,
                'a' => .Aerodynamic,
                's' => .Shiny,
                else => unreachable,
            };

            const criteria_num = try std.fmt.parseInt(usize, text[2..index_of_colon], 10);

            const criteria = switch (text[1]) {
                '>' => Criteria{ .more_than = criteria_num },
                '<' => Criteria{ .less_than = criteria_num },
                else => unreachable,
            };

            return @This(){ .category = category, .criteria = criteria, .destination = text[index_of_colon + 1 ..] };
        } else {
            return @This(){ .category = null, .criteria = null, .destination = text };
        }
    }

    pub fn passing_range(self: @This(), range: Range) ?Range {
        return switch (self.criteria.?) {
            .less_than => |n| if (range.min > n) null else if (range.max >= n) Range{ .min = range.min, .max = n - 1 } else range,
            .more_than => |n| if (range.max < n) null else if (range.min <= n) Range{ .min = n + 1, .max = range.max } else range,
        };
    }

    pub fn failing_range(self: @This(), range: Range) ?Range {
        return switch (self.criteria.?) {
            .less_than => |n| if (range.max >= n and range.min < n) Range{ .min = n, .max = range.max } else if (range.min >= n) range else null,
            .more_than => |n| if (range.min <= n and range.max > n) Range{ .min = range.min, .max = n } else if (range.max <= n) range else null,
        };
    }
};
