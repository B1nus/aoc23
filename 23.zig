const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;

pub fn main() !void {
    const ally = std.heap.page_allocator;
    const grid, const width = try parse_grid(@embedFile("23.txt"), ally);
    const graph = try generate_graph(grid, width, ally);
    graph.print_nodes();
    // std.debug.print("edges: {any}\n", .{graph.edges.items});
    // const max = try most_scenic_walk_length_in_graph(graph, ally);
    // std.debug.print("{d}\n", .{max});
}

fn most_scenic_walk_length_in_graph(graph: Graph, ally: std.mem.Allocator) !usize {
    var walkers = std.ArrayList(GraphWalker).init(ally);
    var seen = std.AutoHashMap([2]usize, void).init(ally);
    try walkers.append(GraphWalker{ .prev = undefined, .node = 0, .cost = 0 });
    try seen.put(.{ 0, 0 }, void{});

    var active_walkers = std.ArrayList(usize).init(ally);
    try active_walkers.append(0);

    var max: usize = 0;
    while (active_walkers.popOrNull()) |walker_i| {
        const walker = walkers.items[walker_i];
        // std.debug.print("{any}\n", .{walker});
        var adjacent = try adjacent_nodes(graph, walker.node, ally);
        // if (walker.node == 1 and walker.prev == 0) {
        //     std.debug.print("{any}\n", .{graph.edges.items});
        //     std.debug.print("{any}\n", .{adjacent.items});
        // }
        // Remove nodes we've already been to
        var i: usize = 0;
        for (adjacent.items) |adj| {
            if (seen.get(.{ walker_i, adj[0] })) |_| {
                _ = adjacent.orderedRemove(i);
            } else {
                i += 1;
            }
        }

        // if (walker.node == 1 and walker.prev == 0) {
        //     std.debug.print("{any}\n", .{graph.edges.items});
        //     std.debug.print("{any}\n", .{adjacent.items});
        // }
        if (adjacent.items.len > 0) {
            if (adjacent.items.len > 1) {
                for (adjacent.items[1..]) |adj| {
                    try walkers.append(GraphWalker{ .prev = walker.node, .node = adj[0], .cost = walker.cost + adj[1] });
                    try seen.put(.{ walkers.items.len - 1, walker.node }, void{});
                    try active_walkers.append(walkers.items.len - 1);
                }
            }
            walkers.items[walker_i].node = adjacent.items[0][0];
            walkers.items[walker_i].cost += adjacent.items[0][1];
            walkers.items[walker_i].prev = walker.node;
            try active_walkers.append(walker_i);
            try seen.put(.{ walker_i, walker.node }, void{});
        } else if (graph.nodes.items[walker.node] == Node.end) {
            // std.debug.print("end\n", .{});
            max = @max(max, walker.cost);
        } else {
            // Do nothing, this walker is lost
        }
    }
    return max;
}

fn adjacent_nodes(graph: Graph, node: usize, ally: std.mem.Allocator) !std.ArrayList([2]usize) {
    var adjacent = std.ArrayList([2]usize).init(ally);
    for (graph.edges.items) |edge| {
        if (edge.nodes[0] == node) {
            try adjacent.append(.{ edge.nodes[1], edge.cost });
        }
        if (edge.nodes[1] == node) {
            try adjacent.append(.{ edge.nodes[0], edge.cost });
        }
    }
    return adjacent;
}

fn generate_graph(grid: []const u8, width: usize, ally: std.mem.Allocator) !Graph {
    // Generate nodes
    var nodes = std.HashMap(Node, void, Node, std.hash_map.default_max_load_percentage).initContext(ally, Node.start);
    try nodes.put(Node.start, void{});
    {
        var walkers = std.ArrayList([2]u8).init(ally);
        var seen = std.AutoHashMap([2]u8, void).init(ally);

        defer walkers.deinit();
        defer seen.deinit();

        while (walkers.popOrNull()) |walker| {
            if (seen.get(walker) == null) {
                try seen.put(walker, void{});
                var new_walkers = std.ArrayList(struct { u8, u8 }).init(ally);
                new_walkers.deinit();

                const x, const y = walker;

                if (y > 0 and grid[x + (y - 1) * width] != '#') try new_walkers.append(.{ x, y - 1 });
                if (y < width - 1 and grid[x + (y + 1) * width] != '#') try new_walkers.append(.{ x, y + 1 });
                if (grid[x - 1 + y * width] != '#') try new_walkers.append(.{ x - 1, y });
                if (grid[x + 1 + y * width] != '#') try new_walkers.append(.{ x + 1, y });

                // Remove seen
                var i: usize = 0;
                for (new_walkers.items) |new_walker| {
                    if (seen.get(new_walker)) |_| {
                        _ = new_walkers.orderedRemove(i);
                    } else {
                        i += 1;
                    }
                }

                if (new_walkers.items.len > 1) {
                    try nodes.put(Node{ .middle = walker }, void{});
                }

                for (new_walkers.items) |new_walker| {
                    try walkers.append(new_walker);
                }
            }
        }
        try nodes.put(Node.end, void{});
    }

    return Graph{ .nodes = nodes, .edges = undefined };
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

const Walker = struct {
    x: u8,
    y: u8,
    d: Dir,
    node: usize,
    cost: usize,
};

const Dir = enum {
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
};

const Graph = struct {
    nodes: std.HashMap(Node, void, Node, std.hash_map.default_max_load_percentage),
    edges: std.HashMap(Edge, void, Edge, std.hash_map.default_max_load_percentage),

    fn print_nodes(self: @This()) void {
        var it = self.nodes.keyIterator();
        while (it.next()) |node| {
            switch (node.*) {
                .start => std.debug.print("start", .{}),
                .end => std.debug.print("end", .{}),
                .middle => |pos| std.debug.print("node({d},{d})", .{ pos[0], pos[0] }),
            }
            std.debug.print("  ", .{});
        }
    }
};

const Edge = struct {
    nodes: [2]usize,
    cost: usize,

    pub fn hash(_: @This(), self: @This()) u64 {
        var h = std.hash.Wyhash.init(0);
        h.update(std.mem.asBytes(self.nodes[0]));
        h.update(std.mem.asBytes(self.nodes[1]));
        h.update(std.mem.asBytes(self.cost));
        return h.final();
    }

    pub fn eql(_: @This(), self: @This(), other: @This()) bool {
        return std.mem.eql(usize, &self.nodes, &other.nodes) and self.cost == other.cost;
    }
};

const Node = union(enum) {
    start,
    middle: [2]u8,
    end,

    pub fn hash(_: @This(), self: @This()) u64 {
        var h = std.hash.Wyhash.init(0);
        switch (self) {
            .start => h.update("y"),
            .end => h.update("x"),
            .middle => {
                h.update(std.mem.asBytes(self.middle[0]));
                h.update(std.mem.asBytes(self.middle[1]));
            },
        }
        return h.final();
    }

    pub fn eql(_: @This(), self: @This(), other: @This()) bool {
        return switch (self) {
            .start => other == Node.start,
            .end => other == Node.end,
            .middle => other == Node.middle and std.mem.eql(u8, &self.middle, &other.middle),
        };
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
