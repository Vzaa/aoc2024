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

var w: i32 = undefined;
var h: i32 = undefined;

fn parseMap(text: Str) !Map {
    var map = Map.init(gpa);

    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c != '.') try map.put(.{ x, y }, c);
            x += 1;
        }
        w = @intCast(x);
    }
    h = @intCast(y);
    return map;
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn diff(a: Point, b: Point) Point {
    return Point{ a[0] - b[0], a[1] - b[1] };
}

fn inMap(p: Point) bool {
    if (p[0] < 0 or p[0] >= w) return false;
    if (p[1] < 0 or p[1] >= h) return false;
    return true;
}

fn p1(text: Str) !usize {
    var map = try parseMap(text);
    defer map.deinit();

    var antinodes = AutoHashMap(Point, void).init(gpa);
    defer antinodes.deinit();

    var iter = map.iterator();
    while (iter.next()) |ea| {
        var iter_inner = map.iterator();
        while (iter_inner.next()) |eb| {
            if (eb.key_ptr == ea.key_ptr) continue;
            if (eb.value_ptr.* != ea.value_ptr.*) continue;
            const pa = ea.key_ptr.*;
            const pb = eb.key_ptr.*;
            const d = diff(pa, pb);
            const anti1 = diff(pb, d);
            const anti2 = add(pa, d);
            if (inMap(anti1)) try antinodes.put(anti1, {});
            if (inMap(anti2)) try antinodes.put(anti2, {});
        }
    }
    return antinodes.count();
}

fn p2(text: Str) !u32 {
    var map = try parseMap(text);
    defer map.deinit();

    var antinodes = AutoHashMap(Point, void).init(gpa);
    defer antinodes.deinit();

    var iter = map.iterator();
    while (iter.next()) |ea| {
        var iter_inner = map.iterator();
        while (iter_inner.next()) |eb| {
            if (eb.key_ptr == ea.key_ptr) continue;
            if (eb.value_ptr.* != ea.value_ptr.*) continue;
            const pa = ea.key_ptr.*;
            const pb = eb.key_ptr.*;
            const d = diff(pa, pb);
            var anti = pa;
            while (inMap(anti)) {
                try antinodes.put(anti, {});
                anti = add(anti, d);
            }
        }
    }
    return antinodes.count();
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
