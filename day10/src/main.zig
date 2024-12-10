const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const fmt = std.fmt;
const Str = []const u8;
const PQ = std.PriorityQueue;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;

const Map = AutoHashMap(Point, u8);

fn parseMap(text: Str) !Map {
    var map = Map.init(gpa);

    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        for (line, 0..) |c, x| {
            try map.put(.{ @intCast(x), y }, try fmt.charToDigit(c, 10));
        }
    }
    return map;
}

const PC = struct {
    p: Point,
    c: u8,
};

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    return std.math.order(a.c, b.c);
}

fn getNeighbors(p: Point) [4]Point {
    const x = p[0];
    const y = p[1];

    const neighbors = [_]Point{
        .{ x - 1, y },
        .{ x + 1, y },
        .{ x, y - 1 },
        .{ x, y + 1 },
    };

    return neighbors;
}

fn ucs(map: *Map, start: Point, tgt: u8, part1: bool) !usize {
    var frontier = PQ(PC, void, compPc).init(gpa, {});
    defer frontier.deinit();

    var visited = AutoHashMap(Point, void).init(gpa);
    defer visited.deinit();

    try frontier.add(PC{ .p = start, .c = 0 });

    var cnt: usize = 0;

    while (frontier.removeOrNull()) |cur| {
        try visited.put(cur.p, {});
        const height = map.get(cur.p).?;

        if (cur.c == tgt) {
            cnt += 1;
            continue;
        }

        const neighbors = getNeighbors(cur.p);

        for (neighbors) |np| {
            if (!visited.contains(np) and map.contains(np)) {
                const height_other = map.get(np).?;
                if (height_other == height + 1) {
                    try frontier.add(PC{ .p = np, .c = height_other });
                    if (part1) try visited.put(np, {});
                }
            }
        }
    }

    return cnt;
}

fn p1(text: Str) !usize {
    var map = try parseMap(text);
    defer map.deinit();

    var iter = map.iterator();
    var sum: usize = 0;
    while (iter.next()) |e| {
        const p = e.key_ptr.*;
        const v = e.value_ptr.*;
        if (v != 0) continue;
        sum += try ucs(&map, p, 9, true);
    }

    return sum;
}

fn p2(text: Str) !usize {
    var map = try parseMap(text);
    defer map.deinit();

    var iter = map.iterator();
    var sum: usize = 0;
    while (iter.next()) |e| {
        const p = e.key_ptr.*;
        const v = e.value_ptr.*;
        if (v != 0) continue;
        sum += try ucs(&map, p, 9, false);
    }

    return sum;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
