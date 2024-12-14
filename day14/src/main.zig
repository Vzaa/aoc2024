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

const Point = [2]i64;

const Robot = struct {
    p: Point,
    v: Point,

    fn parse(text: Str) !Robot {
        var iter = mem.tokenize(u8, text, "pv= ,");
        return .{
            .p = .{
                try fmt.parseInt(i64, iter.next().?, 10),
                try fmt.parseInt(i64, iter.next().?, 10),
            },
            .v = .{
                try fmt.parseInt(i64, iter.next().?, 10),
                try fmt.parseInt(i64, iter.next().?, 10),
            },
        };
    }

    fn move(self: *Robot) void {
        self.p = add(self.p, self.v);
        self.p[0] = @mod(self.p[0], W);
        self.p[1] = @mod(self.p[1], H);
    }
};

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

const W: i64 = 101;
const H: i64 = 103;
const WH = @divTrunc(W, 2);
const HH = @divTrunc(H, 2);

fn p1(text: Str) !usize {
    var lines = mem.splitAny(u8, text, "\n");

    var robots = ArrayList(Robot).init(gpa);
    defer robots.deinit();

    while (lines.next()) |line| {
        const r = try Robot.parse(line);
        try robots.append(r);
    }

    for (0..100) |_| {
        for (robots.items) |*r| {
            r.move();
        }
    }

    var sums = [_]usize{ 0, 0, 0, 0 };

    for (robots.items) |r| {
        if (r.p[0] < WH and r.p[1] < HH) sums[0] += 1;
        if (r.p[0] < WH and r.p[1] > HH) sums[1] += 1;
        if (r.p[0] > WH and r.p[1] < HH) sums[2] += 1;
        if (r.p[0] > WH and r.p[1] > HH) sums[3] += 1;
    }

    var m: usize = 1;
    for (sums) |s| m *= s;

    return m;
}

fn printMap(robots: *ArrayList(Robot)) !void {
    var map = AutoHashMap(Point, void).init(gpa);
    defer map.deinit();
    for (robots.items) |r| try map.put(r.p, {});

    for (0..H) |y| {
        for (0..W) |x| {
            if (map.contains(.{ @intCast(x), @intCast(y) })) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

fn p2(text: Str) !usize {
    var lines = mem.splitAny(u8, text, "\n");

    var robots = ArrayList(Robot).init(gpa);
    defer robots.deinit();

    while (lines.next()) |line| {
        const r = try Robot.parse(line);
        try robots.append(r);
    }

    for (1..10000) |i| {
        for (robots.items) |*r| {
            r.move();
        }
        std.debug.print("Second {}\n", .{i});
        try printMap(&robots);
    }

    return 0;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
