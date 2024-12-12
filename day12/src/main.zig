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
const Map = AutoHashMap(Point, u8);
const PointSet = AutoHashMap(Point, void);

fn parseMap(text: Str) !Map {
    var map = Map.init(gpa);

    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            try map.put(.{ x, y }, c);
            x += 1;
        }
    }
    return map;
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

fn getAll(map: *Map, fill: *PointSet, p: Point) !void {
    if (fill.contains(p)) return;

    const c = map.get(p).?;
    try fill.put(p, {});

    const ns = getNeighbors(p);
    for (ns) |n| {
        const cn = map.get(n) orelse continue;
        if (cn == c) try getAll(map, fill, n);
    }
}

fn p1(text: Str) !usize {
    var map = try parseMap(text);
    defer map.deinit();

    var iter_map = map.iterator();

    var visited = PointSet.init(gpa);
    defer visited.deinit();

    var sum: usize = 0;

    while (iter_map.next()) |e| {
        const p = e.key_ptr.*;
        const c = e.value_ptr.*;
        if (visited.contains(p)) continue;

        var fill = PointSet.init(gpa);
        defer fill.deinit();

        try getAll(&map, &fill, p);

        const area = fill.count();

        var kiter_fill = fill.keyIterator();

        var fences: usize = 0;

        while (kiter_fill.next()) |k| {
            try visited.put(k.*, {});
            const ns = getNeighbors(k.*);
            var cnt: usize = 4;
            for (ns) |n| {
                const cn = map.get(n) orelse continue;
                if (cn == c) cnt -= 1;
            }
            fences += cnt;
        }

        sum += fences * area;
    }

    return sum;
}

// terrible
fn countHFences(fences: *PointSet) usize {
    var count: usize = 0;
    var y: i32 = -1;
    while (y < 150) : (y += 1) {
        var state = false;
        var x: i32 = -1;
        while (x < 150) : (x += 1) {
            const next = fences.contains(.{ @intCast(x), @intCast(y) });
            if (!state and next) {
                count += 1;
                state = true;
            } else if (state and next) {
                // skip
            } else if (state and !next) {
                state = false;
            }
        }
    }
    return count;
}

fn countVFences(fences: *PointSet) usize {
    var count: usize = 0;
    var x: i32 = -1;
    while (x < 150) : (x += 1) {
        var state = false;
        var y: i32 = -1;
        while (y < 150) : (y += 1) {
            const next = fences.contains(.{ @intCast(x), @intCast(y) });
            if (!state and next) {
                count += 1;
                state = true;
            } else if (state and next) {
                // skip
            } else if (state and !next) {
                state = false;
            }
        }
    }
    return count;
}

fn p2(text: Str) !usize {
    var map = try parseMap(text);
    defer map.deinit();

    var iter_map = map.iterator();

    var visited = PointSet.init(gpa);
    defer visited.deinit();

    var sum: usize = 0;

    while (iter_map.next()) |e| {
        const p = e.key_ptr.*;
        const c = e.value_ptr.*;
        if (visited.contains(p)) continue;

        var fill = PointSet.init(gpa);
        defer fill.deinit();

        try getAll(&map, &fill, p);

        const area = fill.count();

        var kiter_fill = fill.keyIterator();

        var l_fences = PointSet.init(gpa);
        var r_fences = PointSet.init(gpa);
        var u_fences = PointSet.init(gpa);
        var d_fences = PointSet.init(gpa);
        defer l_fences.deinit();
        defer r_fences.deinit();
        defer u_fences.deinit();
        defer d_fences.deinit();

        while (kiter_fill.next()) |k| {
            try visited.put(k.*, {});
            const ns = getNeighbors(k.*);

            for (ns, 0..) |n, idx| {
                if (!map.contains(n)) {
                    if (idx == 0) try l_fences.put(n, {});
                    if (idx == 1) try r_fences.put(n, {});
                    if (idx == 2) try u_fences.put(n, {});
                    if (idx == 3) try d_fences.put(n, {});
                } else {
                    const cn = map.get(n).?;
                    if (cn != c) {
                        if (idx == 0) try l_fences.put(n, {});
                        if (idx == 1) try r_fences.put(n, {});
                        if (idx == 2) try u_fences.put(n, {});
                        if (idx == 3) try d_fences.put(n, {});
                    }
                }
            }
        }

        const l = countVFences(&l_fences);
        const r = countVFences(&r_fences);
        const u = countHFences(&u_fences);
        const d = countHFences(&d_fences);
        sum += (l + r + u + d) * area;
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
