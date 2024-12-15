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
const WallMap = AutoHashMap(Point, void);
const BoxMap = AutoHashMap(Point, void);

fn parseMap(text: Str, p: *Point, boxes: *BoxMap, map: *WallMap) !void {
    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '#') {
                try map.put(.{ x, y }, {});
            } else if (c == '@') {
                p[0] = x;
                p[1] = y;
            } else if (c == 'O') {
                try boxes.put(.{ x, y }, {});
            }
            x += 1;
        }
    }
}

fn parseMap2(text: Str, p: *Point, boxes: *BoxMap, map: *WallMap) !void {
    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '#') {
                try map.put(.{ x, y }, {});
                try map.put(.{ x + 1, y }, {});
            } else if (c == '@') {
                p[0] = x;
                p[1] = y;
            } else if (c == 'O') {
                try boxes.put(.{ x, y }, {});
            }
            x += 2;
        }
    }
}

const Dir = enum {
    N,
    S,
    W,
    E,

    fn asVec(self: *const Dir) Point {
        return switch (self.*) {
            Dir.N => .{ 0, -1 },
            Dir.S => .{ 0, 1 },
            Dir.W => .{ -1, 0 },
            Dir.E => .{ 1, 0 },
        };
    }

    fn fromChar(c: u8) Dir {
        switch (c) {
            '<' => return Dir.W,
            '>' => return Dir.E,
            '^' => return Dir.N,
            'v' => return Dir.S,
            else => unreachable,
        }
    }
};

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn isMoveable(map: *WallMap, boxes: *BoxMap, p: Point, v: Point) bool {
    var c = add(p, v);

    while (true) : (c = add(c, v)) {
        if (map.contains(c)) return false;
        if (boxes.contains(c)) continue;
        return true;
    }
}

fn isMoveable2(map: *WallMap, boxes: *BoxMap, p: Point, v: Point) bool {
    var c = add(p, v);

    while (true) : (c = add(c, v)) {
        if (map.contains(c)) return false;
        if (v[1] == 0) {
            if (boxes.contains(c)) continue;
            if (boxes.contains(.{ c[0] - 1, c[1] })) continue;
        }
        if (v[0] == 0) {
            if (boxes.contains(c)) {
                return isMoveable2(map, boxes, c, v) and isMoveable2(map, boxes, .{ c[0] + 1, c[1] }, v);
            }
            if (boxes.contains(.{ c[0] - 1, c[1] })) {
                return isMoveable2(map, boxes, c, v) and isMoveable2(map, boxes, .{ c[0] - 1, c[1] }, v);
            }
            // 1380
        }
        return true;
    }
}

fn moveBoxes2(boxes: *BoxMap, p: Point, v: Point, list: *ArrayList(Point)) !void {
    const c = add(p, v);

    const a = boxes.remove(c);
    const b = boxes.remove(.{ c[0] - 1, c[1] });
    if (v[1] == 0) {
        if (a) try list.append(c);
        if (b) try list.append(.{ c[0] - 1, c[1] });
        if (a) {
            try moveBoxes2(boxes, .{ c[0] + 1, c[1] }, v, list);
        }
        if (b) {
            try moveBoxes2(boxes, .{ c[0] - 1, c[1] }, v, list);
        }
        if (!a and !b) return;
    }
    if (v[0] == 0) {
        if (a) try list.append(c);
        if (b) try list.append(.{ c[0] - 1, c[1] });
        if (a) {
            try moveBoxes2(boxes, c, v, list);
            try moveBoxes2(boxes, .{ c[0] + 1, c[1] }, v, list);
        }
        if (b) {
            try moveBoxes2(boxes, c, v, list);
            try moveBoxes2(boxes, .{ c[0] - 1, c[1] }, v, list);
        }
        if (!a and !b) return;
    }
    // too low 1212660
}

fn moveBoxes(boxes: *BoxMap, p: Point, v: Point) !void {
    var c = add(p, v);

    var list = ArrayList(Point).init(gpa);
    defer list.deinit();

    while (true) : (c = add(c, v)) {
        if (boxes.remove(c)) {
            try list.append(c);
        } else {
            break;
        }
    }

    for (list.items) |b| {
        try boxes.put(add(b, v), {});
    }
}

fn p1(text: Str) !i32 {
    var map = WallMap.init(gpa);
    defer map.deinit();
    var boxes = BoxMap.init(gpa);
    defer boxes.deinit();

    var parts_iter = mem.split(u8, text, "\n\n");

    var pos: Point = undefined;

    try parseMap(parts_iter.next().?, &pos, &boxes, &map);

    var dirs = ArrayList(Point).init(gpa);
    defer dirs.deinit();

    const part = parts_iter.next().?;

    for (part) |c| {
        if (c == '\n') continue;
        try dirs.append(Dir.fromChar(c).asVec());
    }

    for (dirs.items) |d| {
        if (isMoveable(&map, &boxes, pos, d)) {
            try moveBoxes(&boxes, pos, d);
            pos = add(pos, d);
        }
    }

    var kiter = boxes.keyIterator();

    var sum: i32 = 0;
    while (kiter.next()) |b| {
        sum += b[0] + b[1] * 100;
    }

    return sum;
}

fn p2(text: Str) !i32 {
    var map = WallMap.init(gpa);
    defer map.deinit();
    var boxes = BoxMap.init(gpa);
    defer boxes.deinit();

    var parts_iter = mem.split(u8, text, "\n\n");

    var pos: Point = undefined;

    try parseMap2(parts_iter.next().?, &pos, &boxes, &map);

    var dirs = ArrayList(Point).init(gpa);
    defer dirs.deinit();

    const part = parts_iter.next().?;

    for (part) |c| {
        if (c == '\n') continue;
        try dirs.append(Dir.fromChar(c).asVec());
    }

    for (dirs.items) |d| {
        if (isMoveable2(&map, &boxes, pos, d)) {
            var list = ArrayList(Point).init(gpa);
            defer list.deinit();
            try moveBoxes2(&boxes, pos, d, &list);
            pos = add(pos, d);
            for (list.items) |b| {
                try boxes.put(add(b, d), {});
            }
        }
    }

    var kiter = boxes.keyIterator();

    var sum: i32 = 0;
    while (kiter.next()) |b| {
        sum += b[0] + b[1] * 100;
    }

    return sum;
}

fn printb(map: *WallMap, boxes: *BoxMap, pos: Point) void {
    for (0..10) |y| {
        for (0..20) |x| {
            const p = Point{ @intCast(x), @intCast(y) };
            if (map.contains(p)) {
                std.debug.print("#", .{});
            } else if (boxes.contains(p)) {
                std.debug.print("[", .{});
            } else if (boxes.contains(.{ p[0] - 1, p[1] })) {
                std.debug.print("]", .{});
            } else if (pos[0] == p[0] and pos[1] == p[1]) {
                std.debug.print("@", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
