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

const tst: bool = false;

fn parseMap(text: Str, s: *Point, e: *Point) !Map {
    var map = Map.init(gpa);

    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '#') try map.put(.{ x, y }, {});
            if (c == 'S') {
                s[0] = x;
                s[1] = y;
            } else if (c == 'E') {
                e[0] = x;
                e[1] = y;
            }
            x += 1;
        }
    }
    return map;
}

const PC = struct {
    p: Point,
    c: usize,
};

const PC2 = struct {
    p: Point,
    c: usize,
    cheat: usize,
    prev: Point,
};

const State = struct {
    p: Point,
    c: usize,
    cheat: usize = 0,
};

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    return std.math.order(a.c, b.c);
}

fn compPc2(_: void, a: PC2, b: PC2) std.math.Order {
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

const Size: i32 = if (tst) 15 else 141;

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

const Path = AutoHashMap(Point, void);

fn ucs2(map: *Map, start: Point, end: Point, no_cheat: usize, save: usize) !usize {
    var frontier = PQ(PC2, void, compPc2).init(gpa, {});
    defer frontier.deinit();

    const cost_at_most = no_cheat - save;

    var visited = AutoHashMap(State, usize).init(gpa);
    defer visited.deinit();

    try frontier.add(PC2{ .p = start, .c = 0, .cheat = 2, .prev = .{ -1, -1 } });

    var cnt: usize = 0;
    while (frontier.removeOrNull()) |*cur| {
        if (cur.p[0] == end[0] and cur.p[1] == end[1]) {
            cnt += 1;
            continue;
        }

        const nc = cur.c + 1;
        if (nc > cost_at_most) continue;
        const ns = getNeighbors(cur.p);

        for (ns) |n| {
            if (n[0] >= 0 and n[0] < Size and n[1] >= 0 and n[1] < Size) {
                if (cur.prev[0] == n[0] and cur.prev[1] == n[1]) continue;
                var cheat: usize = cur.cheat;
                if (!map.contains(n) and cheat == 2) {
                    cheat = 2;
                } else if (!map.contains(n) and cheat == 0) {
                    cheat = 0;
                } else if (map.contains(n) and cheat == 2) {
                    cheat = 1;
                } else if (!map.contains(n) and cheat == 1) {
                    cheat = 0;
                } else {
                    continue;
                }
                var push = true;
                const state = State{ .c = nc, .p = n, .cheat = cheat };
                if (visited.get(state)) |old_c| {
                    if (old_c <= nc) {
                        push = true;
                    }
                }
                if (push) {
                    try frontier.add(PC2{ .p = n, .c = nc, .cheat = cheat, .prev = cur.p });
                    try visited.put(state, nc);
                }
            }
        }
    }

    return cnt;
}

fn mDist(a: Point, b: Point) i64 {
    const x = @abs(a[0] - b[0]);
    const y = @abs(a[1] - b[1]);
    return x + y;
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

const Memo = AutoHashMap(Point, usize);

fn ucs3(map: *Map, start: Point, end: Point, no_cheat: usize, save: usize) !usize {
    var memo = Memo.init(gpa);
    defer memo.deinit();

    var frontier = PQ(PC, void, compPc).init(gpa, {});
    defer frontier.deinit();

    const cost_at_most = no_cheat - save;

    var visited = AutoHashMap(Point, usize).init(gpa);
    defer visited.deinit();

    try frontier.add(PC{ .p = start, .c = 0 });
    try visited.put(start, 0);

    var cnt: usize = 0;

    while (frontier.removeOrNull()) |cur| {
        if (cur.c > cost_at_most) continue;
        var y: i32 = -20;
        while (y <= 20) : (y += 1) {
            var x: i32 = -20;
            while (x <= 20) : (x += 1) {
                const cp = add(cur.p, Point{ x, y });
                const dist: usize = @intCast(mDist(cur.p, cp));
                if (cp[0] < 0 or cp[0] >= Size or cp[1] < 0 or cp[1] >= Size) {
                    continue;
                }
                if (dist <= 20) {
                    if (cur.c + dist > cost_at_most) continue;
                    if (!map.contains(cp)) {
                        var remain: usize = undefined;
                        if (memo.get(cp)) |r| {
                            remain = r;
                        } else {
                            remain = try ucs(map, cp, end);
                            try memo.put(cp, remain);
                        }

                        if (remain + dist + cur.c <= cost_at_most) {
                            cnt += 1;
                        }
                    }
                }
            }
        }

        const ns = getNeighbors(cur.p);

        for (ns) |n| {
            if (!map.contains(n) and n[0] >= 0 and n[0] < Size and n[1] >= 0 and n[1] < Size) {
                if (visited.get(n)) |_| {
                    continue;
                }
                try frontier.add(PC{ .p = n, .c = cur.c + 1 });
                try visited.put(n, cur.c + 1);
            }
        }
    }

    return cnt;
}

fn p1(text: Str) !usize {
    var start: Point = undefined;
    var end: Point = undefined;

    var map = try parseMap(text, &start, &end);
    defer map.deinit();

    const no_cheat = try ucs(&map, start, end);

    return try ucs2(&map, start, end, no_cheat, 100);
}

fn p2(text: Str) !usize {
    var start: Point = undefined;
    var end: Point = undefined;

    var map = try parseMap(text, &start, &end);
    defer map.deinit();

    const no_cheat = try ucs(&map, start, end);

    return try ucs3(&map, start, end, no_cheat, 100);
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = if (tst) @embedFile("test") else @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
