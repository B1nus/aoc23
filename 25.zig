// Thanks to /u/4HbQ on reddit: https://old.reddit.com/r/adventofcode/comments/18qbsxs/2023_day_25_solutions/ketzp94/
//
// And thanks to @xavdid: https://advent-of-code.xavd.id/writeups/2023/day/25/
//
// And sorry for cheating again. I'm running out of time before advent of code 2024.
const std = @import("std");
const Set = std.StringHashMap(void);
const input = @embedFile("25.txt");

pub fn main() !void {
    const ally = std.heap.page_allocator;
    var nodes = std.StringHashMap(Set).init(ally);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const self = line[0..3];
        var others = std.mem.splitScalar(u8, line[5..], ' ');

        while (others.next()) |other| {
            try put_in_inner_hashmap(&nodes, self, other);
            try put_in_inner_hashmap(&nodes, other, self);
        }
    }
    const graph = nodes;

    // Expand the left set untill we have exactly three connections to the right set.
    var left = Set.init(ally);
    var right = try quantity_discrimination(nodes, left);

    while (neighbour_connections(graph, left, right) != 3) {
        // while (it.next()) |next| {
        //     var it = right.iterator();
        //     std.debug.print("{s} ", .{next.key_ptr.*});
        // }
        // std.debug.print("\n", .{});
        const max = max_connections(graph, right, left);
        // std.debug.print("max:{s}\n", .{max});
        try left.put(max, void{});
        _ = right.remove(max);
    }
    std.debug.print("Day 25 >> {d}\n", .{left.count() * right.count()});

    // var it = nodes.iterator();
    // while (it.next()) |entry| {
    //     std.debug.print("{s} -> ", .{entry.key_ptr.*});
    //     var it2 = entry.value_ptr.*.keyIterator();
    //     while (it2.next()) |key| {
    //         std.debug.print("{s} ", .{key.*});
    //     }
    //     std.debug.print("\n", .{});
    // }
}

fn neighbour_connections(nodes: std.StringHashMap(Set), left: Set, right: Set) usize {
    var sum: usize = 0;
    var it = left.keyIterator();
    while (it.next()) |key| {
        sum += same_count(nodes.get(key.*).?, right);
    }
    return sum;
}

// Could be done the same time as the sum function. But we don't really care for performance here so let's not worry about that.
fn max_connections(nodes: std.StringHashMap(Set), left: Set, right: Set) []const u8 {
    var max: []const u8 = undefined;
    var max_same_count: usize = 0;
    var it = left.keyIterator();
    while (it.next()) |key| {
        const my_max = same_count(nodes.get(key.*).?, right);
        if (my_max >= max_same_count) {
            max_same_count = my_max;
            max = key.*;
        }
    }
    return max;
}

fn same_count(set1: Set, set2: Set) usize {
    var count: usize = 0;
    var it = set1.keyIterator();
    while (it.next()) |set1_key| {
        if (set2.get(set1_key.*)) |_| {
            count += 1;
        }
    }
    return count;
}

fn quantity_discrimination(minuend: std.StringHashMap(Set), subtrahend: Set) !Set {
    const ally = minuend.allocator;
    var contains = Set.init(ally);
    var minuend_it = minuend.keyIterator();
    while (minuend_it.next()) |it| {
        try contains.put(it.*, void{});
    }
    var subtrahend_it = subtrahend.keyIterator();
    while (subtrahend_it.next()) |it| {
        _ = contains.remove(it.*);
    }
    return contains;
}

fn put_in_inner_hashmap(hash_map: *std.StringHashMap(Set), outer_key: []const u8, inner_key: []const u8) !void {
    if (hash_map.getPtr(outer_key)) |outer_val| {
        try outer_val.*.put(inner_key, void{});
    } else {
        var inner_hash = Set.init(hash_map.allocator);
        try inner_hash.put(inner_key, void{});
        try hash_map.put(outer_key, inner_hash);
    }
}
