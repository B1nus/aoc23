const std = @import("std");
const List = std.ArrayList;

pub fn main() !void {
    const ally = std.heap.page_allocator;
    const grid, const width = try parse_grid(@embedFile("23.txt"), ally);
    const graph = try generate_graph(grid, width, ally);
    graph.print_grid(grid, width, null);
    graph.print_edges();
}

// fn most_scenic_walk_length_in_graph(graph: Graph, ally: std.mem.Allocator) !usize {
// }

fn adjacent_nodes(graph: Graph, node: usize, ally: std.mem.Allocator) !std.ArrayList(Edge) {
    var adjacent = List(Edge).init(ally);
    for (graph.edges.items) |edge| {
        if (edge.nodes[0] == node) {
            try adjacent.append(Edge{ node, edge.nodes[1], edge.cost });
        }
        if (edge.nodes[1] == node) {
            try adjacent.append(Edge{ node, edge.nodes[0], edge.cost });
        }
    }
    return adjacent;
}

fn contains(comptime T: type, items: []T, item: T) bool {
    return index_of(T, items, item) != null;
}

fn index_of(comptime T: type, items: []T, item: T) ?usize {
    for (items, 0..) |item_, i| {
        if (item_.eql(item)) {
            return i;
        }
    }
    return null;
}

fn generate_graph(grid: []const u8, width: usize, ally: std.mem.Allocator) !Graph {
    var edges = List(Edge).init(ally);
    var nodes = List(Node).init(ally);
    try nodes.append(Node{ .x = 1, .y = 0 });

    var starts = List(struct { u8, u8, Dir, usize }).init(ally);
    defer starts.deinit();

    try starts.append(.{ 1, 0, Dir.down, 0 });
    while (starts.popOrNull()) |start| {
        var x, var y, const d, const start_node = start;

        var next = List(Dir).init(ally);
        defer next.deinit();

        var steps: usize = 0;

        // Walk until you find a node or the exit.
        try next.append(d);
        while (next.items.len == 1) : (steps += 1) {
            // Move to the new location
            const nd = next.items[0];
            const nx, const ny = nd.move(x, y);
            x = nx;
            y = ny;

            std.debug.print("({d}, {d}) {s}\n", .{ x, y, @tagName(nd) });
            const graph = Graph{ .nodes = nodes, .edges = edges };
            graph.print_grid(grid, width, .{ x, y, nd });
            graph.print_edges();
            _ = try std.io.getStdIn().reader().readByte();

            next.clearAndFree();

            // You've reached the end, stop.
            if (x == width - 2 and y == grid.len / width - 1) {
                try nodes.append(Node{ .x = x, .y = y });
                try edges.append(Edge.new(start_node, nodes.items.len - 1, steps + 1));
                break;
            }

            // Add all adjacent locations
            for ([_]Dir{ Dir.up, Dir.down, Dir.left, Dir.right }) |d_| {
                if (d_ != nd.opposite()) {
                    const _x, const _y = d_.move(x, y);
                    if (grid[_x + width * _y] != '#') {
                        try next.append(d_);
                    }
                }
            }
        }

        if (next.items.len > 1) {
            const node = Node{ .x = x, .y = y };
            if (index_of(Node, nodes.items, node)) |index| {
                const edge = Edge.new(start_node, index, steps);
                if (!contains(Edge, edges.items, edge)) {
                    try edges.append(edge);
                }
            } else {
                try nodes.append(node);
                const node_i = nodes.items.len - 1;
                const edge = Edge.new(start_node, node_i, steps);
                if (!contains(Edge, edges.items, edge)) {
                    try edges.append(edge);
                }
                for (next.items) |next_| {
                    try starts.append(.{ x, y, next_, node_i });
                }
            }
        }
    }

    return Graph{ .nodes = nodes, .edges = edges };
}

// Return false if already in the list
fn append_if_not_already(comptime T: type, item: T, list: *std.ArrayList(T)) !bool {
    var has: bool = false;
    for (list.items) |e| {
        if (e.eql(item)) {
            has = true;
            break;
        }
    }
    if (!has) {
        try list.append(item);
    }
    return !has;
}

const Dir = enum(u8) {
    up,
    down,
    left,
    right,

    fn opposite(self: @This()) @This() {
        return switch (self) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        };
    }

    fn move(self: @This(), x: u8, y: u8) struct { u8, u8 } {
        return switch (self) {
            .up => .{ x, y - 1 },
            .down => .{ x, y + 1 },
            .left => .{ x - 1, y },
            .right => .{ x + 1, y },
        };
    }

    fn as_char(self: @This()) u8 {
        return switch (self) {
            .up => '^',
            .down => 'v',
            .left => '<',
            .right => '>',
        };
    }
};

const Graph = struct {
    nodes: List(Node),
    edges: List(Edge),

    fn print_grid(self: @This(), grid: []const u8, width: usize, walker: ?struct { u8, u8, Dir }) void {
        const height = grid.len / width;
        for (0..height) |y_| {
            for (0..width) |x_| {
                const x: u8 = @intCast(x_);
                const y: u8 = @intCast(y_);
                if (index_of(Node, self.nodes.items, Node{ .x = x, .y = y })) |i| {
                    std.debug.print("{X}", .{i});
                } else if (walker != null and walker.?.@"0" == x and walker.?.@"1" == y) {
                    std.debug.print("\x1b[31m{c}\x1b[0m", .{walker.?.@"2".as_char()});
                } else {
                    std.debug.print("{c}", .{grid[x + y * width]});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    fn print_edges(self: @This()) void {
        for (self.edges.items) |edge| {
            std.debug.print("{x} - {x} cost:{d}\n", .{ edge.node1, edge.node2, edge.cost });
        }
    }
};

const Edge = struct {
    node1: usize,
    node2: usize,
    cost: usize,

    fn new(node1: usize, node2: usize, cost: usize) @This() {
        // Make sure it's sorted so each edge has one canonical representation
        std.debug.assert(cost > 0);
        std.debug.assert(node1 != node2);
        return @This(){
            .node1 = @min(node1, node2),
            .node2 = @max(node1, node2),
            .cost = cost,
        };
    }

    pub fn eql(self: @This(), other: @This()) bool {
        std.debug.assert(self.node1 < self.node2);
        std.debug.assert(other.node1 < other.node2);
        return self.node1 == other.node1 and self.node2 == other.node2;
    }
};

const Node = struct {
    x: u8,
    y: u8,

    pub fn eql(self: @This(), other: @This()) bool {
        return self.x == other.x and self.y == other.y;
    }
};

fn parse_grid(input: []const u8, ally: std.mem.Allocator) !struct { []const u8, usize } {
    var lines = std.mem.splitScalar(u8, input, '\n');
    const width = lines.peek().?.len;
    var characters = std.ArrayList(u8).init(ally);
    while (lines.next()) |line| {
        try characters.appendSlice(line);
    }
    return .{ characters.items, width };
}
