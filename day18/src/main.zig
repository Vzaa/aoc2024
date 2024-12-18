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
const Map = AutoHashMap(Point, void);

const Size: i32 = 71;

const PC = struct {
    p: Point,
    c: usize,
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

fn ucs(map: *Map, start: Point, end: Point) !usize {
    var frontier = PQ(PC, void, compPc).init(gpa, {});
    defer frontier.deinit();

    var visited = AutoHashMap(Point, usize).init(gpa);
    defer visited.deinit();

    try frontier.add(PC{ .p = start, .c = 0 });

    while (frontier.removeOrNull()) |cur| {
        if (cur.p[0] == end[0] and cur.p[1] == end[1]) {
            return cur.c;
        }

        const ns = getNeighbors(cur.p);

        for (ns) |n| {
            if (!map.contains(n) and n[0] >= 0 and n[0] < Size and n[1] >= 0 and n[1] < Size) {
                var push = true;
                if (visited.get(n)) |old_c| {
                    if (old_c <= cur.c + 1) {
                        push = false;
                    }
                }
                if (push) {
                    try frontier.add(PC{ .p = n, .c = cur.c + 1 });
                    try visited.put(n, cur.c + 1);
                }
            }
        }
    }

    return 0;
}

fn p1(text: Str) !usize {
    var map = Map.init(gpa);
    defer map.deinit();

    var line_iter = mem.split(u8, text, "\n");
    var cnt: usize = 0;
    while (line_iter.next()) |line| : (cnt += 1) {
        if (cnt >= 1024) break;
        var num_iter = mem.tokenize(u8, line, ",");
        const x = try fmt.parseInt(i32, num_iter.next().?, 10);
        const y = try fmt.parseInt(i32, num_iter.next().?, 10);
        try map.put(.{ x, y }, {});
    }

    return try ucs(&map, .{ 0, 0 }, .{ Size - 1, Size - 1 });
}

fn p2(text: Str) !void {
    var map = Map.init(gpa);
    defer map.deinit();

    var line_iter = mem.split(u8, text, "\n");
    var cnt: usize = 0;

    while (line_iter.next()) |line| : (cnt += 1) {
        var num_iter = mem.tokenize(u8, line, ",");
        const x = try fmt.parseInt(i32, num_iter.next().?, 10);
        const y = try fmt.parseInt(i32, num_iter.next().?, 10);
        try map.put(.{ x, y }, {});
        if (try ucs(&map, .{ 0, 0 }, .{ Size - 1, Size - 1 }) == 0) {
            std.debug.print("{},{}\n", .{ x, y });
            return;
        }
    }
    return;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: ", .{});
    try p2(trimmed);
}
