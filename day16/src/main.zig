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

const Dir = enum {
    N,
    S,
    W,
    E,

    fn turnRight(self: *const Dir) Dir {
        return switch (self.*) {
            Dir.N => Dir.E,
            Dir.S => Dir.W,
            Dir.W => Dir.N,
            Dir.E => Dir.S,
        };
    }

    fn turnLeft(self: *const Dir) Dir {
        return switch (self.*) {
            Dir.N => Dir.W,
            Dir.S => Dir.E,
            Dir.W => Dir.S,
            Dir.E => Dir.N,
        };
    }

    fn asVec(self: *const Dir) Point {
        return switch (self.*) {
            Dir.N => .{ 0, -1 },
            Dir.S => .{ 0, 1 },
            Dir.W => .{ -1, 0 },
            Dir.E => .{ 1, 0 },
        };
    }
};

const PC = struct {
    p: Point,
    c: usize,
    d: Dir,
};

const PC2 = struct { p: Point, c: usize, d: Dir, ps: AutoHashMap(Point, void) };

const PD = struct {
    p: Point,
    d: Dir,
};

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    return std.math.order(a.c, b.c);
}

fn compPc2(_: void, a: PC2, b: PC2) std.math.Order {
    return std.math.order(a.c, b.c);
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn ucs(map: *Map, start: Point, end: Point) !usize {
    var frontier = PQ(PC, void, compPc).init(gpa, {});
    defer frontier.deinit();

    var visited = AutoHashMap(PD, usize).init(gpa);
    defer visited.deinit();

    try frontier.add(PC{ .p = start, .c = 0, .d = Dir.E });

    while (frontier.removeOrNull()) |*cur| {
        if (cur.p[0] == end[0] and cur.p[1] == end[1]) {
            return cur.c;
        }

        const list: [3]PC = .{
            PC{ .p = add(cur.p, cur.d.asVec()), .d = cur.d, .c = cur.c + 1 },
            PC{ .p = cur.p, .d = cur.d.turnLeft(), .c = cur.c + 1000 },
            PC{ .p = cur.p, .d = cur.d.turnRight(), .c = cur.c + 1000 },
        };

        for (list) |l| {
            if (!map.contains(l.p)) {
                const npd = PD{ .p = l.p, .d = l.d };
                var push = true;
                if (visited.get(npd)) |old_c| {
                    if (old_c <= l.c) {
                        push = false;
                    }
                }
                if (push) {
                    try frontier.add(PC{ .p = l.p, .c = l.c, .d = l.d });
                    try visited.put(npd, l.c);
                }
            }
        }
    }

    return 0;
}

fn ucs2(map: *Map, start: Point, end: Point, best: usize) !usize {
    var frontier = PQ(PC2, void, compPc2).init(gpa, {});
    defer frontier.deinit();

    var best_pos = AutoHashMap(Point, void).init(gpa);
    defer best_pos.deinit();

    var visited = AutoHashMap(PD, usize).init(gpa);
    defer visited.deinit();

    var ps = AutoHashMap(Point, void).init(gpa);

    try ps.put(start, {});

    try frontier.add(PC2{ .p = start, .c = 0, .d = Dir.E, .ps = ps });

    while (frontier.removeOrNull()) |*cur| {
        // why?
        defer @constCast(cur).ps.deinit();

        if (cur.p[0] == end[0] and cur.p[1] == end[1]) {
            var kiter = cur.ps.keyIterator();
            while (kiter.next()) |p| try best_pos.put(p.*, {});
            continue;
        }

        const list: [3]PC = .{
            PC{ .p = add(cur.p, cur.d.asVec()), .d = cur.d, .c = cur.c + 1 },
            PC{ .p = cur.p, .d = cur.d.turnLeft(), .c = cur.c + 1000 },
            PC{ .p = cur.p, .d = cur.d.turnRight(), .c = cur.c + 1000 },
        };

        for (list) |l| {
            if (!map.contains(l.p)) {
                const npd = PD{ .p = l.p, .d = l.d };
                if (l.c > best) continue;
                var push = true;
                if (visited.get(npd)) |old_c| {
                    if (old_c < l.c) {
                        push = false;
                    }
                }
                if (push) {
                    var psc = try cur.ps.clone();
                    try psc.put(l.p, {});
                    try frontier.add(PC2{ .p = l.p, .c = l.c, .d = l.d, .ps = psc });
                    try visited.put(npd, l.c);
                }
            }
        }
    }

    return best_pos.count();
}

fn p1(text: Str) !usize {
    var start: Point = undefined;
    var end: Point = undefined;

    var map = try parseMap(text, &start, &end);
    defer map.deinit();

    return try ucs(&map, start, end);
}

fn p2(text: Str) !usize {
    var start: Point = undefined;
    var end: Point = undefined;

    var map = try parseMap(text, &start, &end);
    defer map.deinit();

    const best = try p1(text);

    return try ucs2(&map, start, end, best);
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
