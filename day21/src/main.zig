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

const tst: bool = false;

const Point = [2]i32;
const Map = AutoHashMap(Point, u8);
const Path = ArrayList(u8);

const numpad_str = "789\n456\n123\n#0A";
const dirpad_str = "#^A\n<v>";

fn parseMap(text: Str) !Map {
    var map = Map.init(gpa);
    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        for (line, 0..) |c, x| {
            if (c != '#') try map.put(.{ @intCast(x), y }, c);
        }
    }
    return map;
}

const PC = struct {
    p: Point,
    c: usize,
    path: Path,
};

fn getDist(a: u8, b: u8) usize {
    if (a == b) return 0;

    if (a == '<') {
        if (b == '>') return 3;
        if (b == 'v') return 2;
        if (b == '^') return 3;
        if (b == 'A') return 4;
    }

    if (a == '>') {
        if (b == '<') return 3;
        if (b == 'v') return 2;
        if (b == '^') return 3;
        if (b == 'A') return 2;
    }

    if (a == '^') {
        if (b == '<') return 3;
        if (b == 'v') return 2;
        if (b == '>') return 3;
        if (b == 'A') return 2;
    }

    if (a == 'v') {
        if (b == 'A') return 3;
        return 2;
    }

    unreachable;
}

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    const cmp = std.math.order(a.c, b.c);
    if (cmp != math.Order.eq) return cmp;

    var flips_a: usize = 0;
    var w_iter = mem.window(u8, a.path.items, 2, 1);
    while (w_iter.next()) |btns| {
        if (btns.len < 2) break;
        if (btns[0] != btns[1]) flips_a += getDist(btns[0], btns[1]);
    }

    var flips_b: usize = 0;
    w_iter = mem.window(u8, b.path.items, 2, 1);
    while (w_iter.next()) |btns| {
        if (btns.len < 2) break;
        if (btns[0] != btns[1]) flips_b += getDist(btns[0], btns[1]);
    }

    return std.math.order(flips_a, flips_b);
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

fn shortestPath(map: *Map, start: *Point, end: u8) !Path {
    var frontier = PQ(PC, void, compPc).init(gpa, {});
    defer frontier.deinit();

    var visited = AutoHashMap(Point, usize).init(gpa);
    defer visited.deinit();

    var ipath = Path.init(gpa);
    if (map.get(start.*)) |c| {
        if (c == end) {
            try ipath.append('A');
        }
    }

    try frontier.add(PC{ .p = start.*, .c = 0, .path = ipath });
    defer for (frontier.items) |*f| @constCast(f).path.deinit();

    while (frontier.removeOrNull()) |*cur| {
        if (map.get(cur.p)) |c| {
            if (c == end) {
                start.* = cur.p;
                return cur.path;
            }
        }
        defer @constCast(cur).path.deinit();

        const ns = getNeighbors(cur.p);
        const dirs = "<>^v";

        for (ns, dirs) |n, d| {
            if (map.contains(n)) {
                var push = true;
                if (visited.get(n)) |old_c| {
                    if (old_c < cur.c + 1) {
                        push = false;
                    }
                }
                if (push) {
                    var npath = try cur.path.clone();
                    try npath.append(d);
                    if (map.get(n)) |c| {
                        if (c == end) {
                            try npath.append('A');
                        }
                    }
                    try frontier.add(PC{ .p = n, .c = cur.c + 1, .path = npath });
                    try visited.put(n, cur.c + 1);
                }
            }
        }
    }

    unreachable;
}

// based on mem.trimLeft
pub fn takeLeft(comptime T: type, slice: []const T, values_to_take: []const T) []const T {
    var end: usize = 0;
    while (end < slice.len and mem.indexOfScalar(T, values_to_take, slice[end]) != null) : (end += 1) {}
    return slice[0..end];
}

fn p1(text: Str) !usize {
    var numpad = try parseMap(numpad_str);
    defer numpad.deinit();
    var dirpad = try parseMap(dirpad_str);
    defer dirpad.deinit();

    var line_iter = mem.split(u8, text, "\n");

    var sum: usize = 0;
    while (line_iter.next()) |line| {
        var p = Point{ 2, 3 };
        var numpad_path = Path.init(gpa);
        defer numpad_path.deinit();
        for (line) |c| {
            var to_btn = try shortestPath(&numpad, &p, c);
            defer to_btn.deinit();
            try numpad_path.appendSlice(to_btn.items);
        }

        var dirpad_path_a = Path.init(gpa);
        defer dirpad_path_a.deinit();
        var dirpad_path_b = Path.init(gpa);
        defer dirpad_path_b.deinit();

        var tgt = numpad_path.items;
        var pad = &dirpad_path_a;

        for (0..2) |i| {
            if (i % 2 == 0) {
                pad = &dirpad_path_a;
            } else {
                pad = &dirpad_path_b;
            }
            pad.clearRetainingCapacity();
            p = Point{ 2, 0 };
            for (tgt) |c| {
                const to_btn = try shortestPath(&dirpad, &p, c);
                defer to_btn.deinit();
                try pad.appendSlice(to_btn.items);
            }
            tgt = pad.items;
        }

        const nums = takeLeft(u8, line, "0123456789");

        sum += try fmt.parseInt(usize, nums, 10) * pad.items.len;
    }

    return sum;
}

const Memo = StringHashMap(usize);

fn rec(text: Str, depth: usize, dirpad: *Map, dmemos: []Memo) !usize {
    var p = Point{ 2, 0 };
    var cnt: usize = 0;

    if (depth == 0) return text.len;

    for (text) |c| {
        const to_btn = try shortestPath(dirpad, &p, c);
        defer to_btn.deinit();
        if (dmemos[depth].get(to_btn.items)) |m| {
            cnt += m;
        } else {
            const m = try rec(to_btn.items, depth - 1, dirpad, dmemos);
            try dmemos[depth].put(try gpa.dupe(u8, to_btn.items), m);
            cnt += m;
        }
    }

    return cnt;
}

fn p2(text: Str) !usize {
    var numpad = try parseMap(numpad_str);
    defer numpad.deinit();
    var dirpad = try parseMap(dirpad_str);
    defer dirpad.deinit();

    var line_iter = mem.split(u8, text, "\n");

    var sum: usize = 0;
    while (line_iter.next()) |line| {
        var p = Point{ 2, 3 };
        var numpad_path = Path.init(gpa);
        defer numpad_path.deinit();
        for (line) |c| {
            var to_btn = try shortestPath(&numpad, &p, c);
            defer to_btn.deinit();
            try numpad_path.appendSlice(to_btn.items);
        }

        var dirpad_path_a = Path.init(gpa);
        defer dirpad_path_a.deinit();
        var dirpad_path_b = Path.init(gpa);
        defer dirpad_path_b.deinit();

        const tgt = numpad_path.items;

        var dmemos = ArrayList(Memo).init(gpa);
        defer dmemos.deinit();
        for (0..26) |_| {
            try dmemos.append(Memo.init(gpa));
        }
        defer {
            for (dmemos.items) |*d| {
                var it = d.iterator();
                while (it.next()) |entry| {
                    gpa.free(entry.key_ptr.*);
                }
                d.deinit();
            }
        }

        const presses = try rec(tgt, 25, &dirpad, dmemos.items);

        const nums = takeLeft(u8, line, "0123456789");
        sum += try fmt.parseInt(usize, nums, 10) * presses;
    }

    return sum;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = if (tst) @embedFile("test") else @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
