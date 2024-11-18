const std = @import("std");

pub fn main() !void {
    // Parse Input
    var input = std.mem.splitSequence(u8, @embedFile("19.txt"), "\n\n");
    var workflow_iter = std.mem.splitScalar(u8, input.next().?, '\n');
    var part_iter = std.mem.splitScalar(u8, input.next().?, '\n');

    var workflows = std.StringHashMap(Workflow).init(std.heap.page_allocator);
    while (workflow_iter.next()) |workflow_str| {
        if (workflow_str.len > 0) {
            const workflow = try Workflow.parse(workflow_str);
            try workflows.put(workflow.label, workflow);
        }
    }

    var sum: usize = 0;
    while (part_iter.next()) |part_str| {
        if (part_str.len > 0) {
            const part = try Part.parse(part_str);
            var destination = Destination{ .label = "in" };
            // std.debug.print("{any}:", .{part});

            while (destination == Destination.label) {
                destination = workflows.get(destination.label).?.process_part(part);
            }

            if (destination == Destination.accepted) {
                // std.debug.print(" -> A\n", .{});
                sum += part.sum();
            } else {
                // std.debug.print(" -> R\n", .{});
            }
        }
    }

    std.debug.print("Day 19 >> {d}\n", .{sum});
}

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

    pub fn process_part(self: @This(), part: Part) Destination {
        for (self.rules) |rule_| {
            if (rule_) |rule| {
                if (rule.process_part(part)) {
                    return rule.destination;
                } else {
                    continue;
                }
            }
        }
        return Destination.accepted;
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
    destination: Destination,

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

            const destination = switch (text[index_of_colon + 1]) {
                'R' => Destination.rejected,
                'A' => Destination.accepted,
                else => Destination{ .label = text[index_of_colon + 1 ..] },
            };

            return @This(){ .category = category, .criteria = criteria, .destination = destination };
        } else {
            const destination = switch (text[0]) {
                'R' => Destination.rejected,
                'A' => Destination.accepted,
                else => Destination{ .label = text },
            };
            return @This(){ .category = null, .criteria = null, .destination = destination };
        }
    }

    pub fn process_part(self: @This(), part: Part) bool {
        if (self.category) |category| {
            const measure = switch (category) {
                .Cool => part.x,
                .Musical => part.m,
                .Aerodynamic => part.a,
                .Shiny => part.s,
            };

            if (self.criteria) |criteria| {
                switch (criteria) {
                    Criteria.more_than => |n| return measure > n,
                    Criteria.less_than => |n| return measure < n,
                }
            }
        }

        return true;
    }
};

const Part = struct {
    x: usize,
    m: usize,
    a: usize,
    s: usize,

    pub fn parse(line: []const u8) !@This() {
        var parts = std.mem.splitScalar(u8, line[1 .. line.len - 1], ',');

        const x = try std.fmt.parseInt(usize, parts.next().?[2..], 10);
        const m = try std.fmt.parseInt(usize, parts.next().?[2..], 10);
        const a = try std.fmt.parseInt(usize, parts.next().?[2..], 10);
        const s = try std.fmt.parseInt(usize, parts.next().?[2..], 10);

        return @This(){ .x = x, .m = m, .a = a, .s = s };
    }

    pub fn sum(self: @This()) usize {
        return self.x + self.m + self.a + self.s;
    }
};
