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

const dirs = [9]Point{
    .{ -1, -1 },
    .{ 0, -1 },
    .{ 1, -1 },

    .{ -1, 0 },
    .{ 0, 0 },
    .{ 1, 0 },

    .{ -1, 1 },
    .{ 0, 1 },
    .{ 1, 1 },
};

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

const xmas = "XMAS";

fn p1(text: Str) !u32 {
    var line_iter = mem.split(u8, text, "\n");

    var map = Map.init(gpa);
    defer map.deinit();

    {
        var y: i32 = 0;
        while (line_iter.next()) |line| : (y += 1) {
            for (line, 0..) |c, x| {
                try map.put(.{ @intCast(x), y }, c);
            }
        }
    }

    var cnt: u32 = 0;

    var kiter = map.keyIterator();
    while (kiter.next()) |s| {
        for (dirs) |dir| {
            var p = s.*;
            for (xmas[0..], 0..) |c, i| {
                const v = map.get(p) orelse break;
                if (v != c) break;
                p = add(p, dir);
                if (i == xmas.len - 1) cnt += 1;
            }
        }
    }

    return cnt;
}

fn cross_a(p: Point) [3]Point {
    const x = p[0];
    const y = p[1];

    const cross_ap = [_]Point{ .{ x - 1, y - 1 }, .{ x, y }, .{ x + 1, y + 1 } };

    return cross_ap;
}

fn cross_b(p: Point) [3]Point {
    const x = p[0];
    const y = p[1];

    const cross_p = [_]Point{ .{ x - 1, y + 1 }, .{ x, y }, .{ x + 1, y - 1 } };

    return cross_p;
}

fn p2(text: Str) !u32 {
    var line_iter = mem.split(u8, text, "\n");

    var map = Map.init(gpa);
    defer map.deinit();

    {
        var y: i32 = 0;
        while (line_iter.next()) |line| : (y += 1) {
            for (line, 0..) |c, x| {
                try map.put(.{ @intCast(x), y }, c);
            }
        }
    }

    var cnt: u32 = 0;
    var kiter = map.keyIterator();
    while (kiter.next()) |p| {
        const a = cross_a(p.*);
        var txt: [3]u8 = .{0} ** 3;
        for (a, 0..) |pos, idx| {
            const v = map.get(pos) orelse break;
            txt[idx] = v;
        }
        if (!mem.eql(u8, &txt, "SAM") and !mem.eql(u8, &txt, "MAS")) continue;

        const b = cross_b(p.*);
        for (b, 0..) |pos, idx| {
            const v = map.get(pos) orelse break;
            txt[idx] = v;
        }
        if (!mem.eql(u8, &txt, "SAM") and !mem.eql(u8, &txt, "MAS")) continue;

        cnt += 1;
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
