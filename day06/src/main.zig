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

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;

const Tile = enum { Wall, Open };
const WallMap = AutoHashMap(Point, Tile);

const Dir = enum {
    N,
    S,
    W,
    E,

    fn turnRight(self: *Dir) Dir {
        return switch (self.*) {
            Dir.N => Dir.E,
            Dir.S => Dir.W,
            Dir.W => Dir.N,
            Dir.E => Dir.S,
        };
    }

    fn asVec(self: *Dir) Point {
        return switch (self.*) {
            Dir.N => .{ 0, -1 },
            Dir.S => .{ 0, 1 },
            Dir.W => .{ -1, 0 },
            Dir.E => .{ 1, 0 },
        };
    }
};

fn parseMap(text: Str, p: *Point) !WallMap {
    var map = WallMap.init(gpa);

    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '#') {
                try map.put(.{ x, y }, Tile.Wall);
            } else if (c == '^') {
                try map.put(.{ x, y }, Tile.Open);
                p[0] = x;
                p[1] = y;
            } else {
                try map.put(.{ x, y }, Tile.Open);
            }
            x += 1;
        }
    }
    return map;
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn p1(text: Str) !usize {
    var p: Point = undefined;
    var d = Dir.N;
    var map = try parseMap(text, &p);
    defer map.deinit();

    var past = AutoHashMap(Point, void).init(gpa);
    defer past.deinit();

    while (map.contains(p)) {
        const v = d.asVec();
        const next = add(v, p);
        try past.put(p, {});

        if (map.get(next)) |t| {
            if (t == Tile.Wall) {
                d = d.turnRight();
                continue;
            }
        }
        p = next;
    }

    return past.count();
}

const State = struct {
    p: Point,
    d: Dir,
};

fn p2(text: Str) !usize {
    var p_init: Point = undefined;
    var map = try parseMap(text, &p_init);
    defer map.deinit();

    var cnt: usize = 0;

    var p1_past = AutoHashMap(Point, void).init(gpa);
    defer p1_past.deinit();
    {
        var p = p_init;
        var d = Dir.N;

        while (map.contains(p)) {
            const v = d.asVec();
            const next = add(v, p);
            try p1_past.put(p, {});

            if (map.get(next)) |t| {
                if (t == Tile.Wall) {
                    d = d.turnRight();
                    continue;
                }
            }
            p = next;
        }
    }

    var past = AutoHashMap(State, void).init(gpa);
    defer past.deinit();
    var kiter = p1_past.keyIterator();
    while (kiter.next()) |e| {
        const c = map.getPtr(e.*) orelse unreachable;
        if (e[0] == p_init[0] and e[1] == p_init[1]) continue;

        past.clearRetainingCapacity();

        c.* = Tile.Wall;
        defer c.* = Tile.Open;

        var p = p_init;
        var d = Dir.N;

        while (map.contains(p)) {
            const v = d.asVec();
            const next = add(v, p);

            if (past.contains(.{ .d = d, .p = p })) {
                cnt += 1;
                break;
            }
            try past.put(.{ .d = d, .p = p }, {});

            if (map.get(next)) |t| {
                if (t == Tile.Wall) {
                    d = d.turnRight();
                    continue;
                }
            }
            p = next;
        }
    }

    return cnt;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
