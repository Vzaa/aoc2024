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

const Name = [2]u8;

const Links = AutoHashMap(Name, ArrayList(Name));
const LSet = AutoHashMap(Name, void);
const LinksH = AutoHashMap(Name, LSet);

const Path3 = [3]Name;
const Path3Str = [6]u8;

const NC = struct {
    n: Name,
    c: usize,
    p: Path3,
};

const State = struct {
    list: ArrayList(Name),
};

fn compNc(_: void, a: NC, b: NC) std.math.Order {
    return std.math.order(a.c, b.c);
}

fn find3(links: *Links, name: Name, paths: *ArrayList(Path3)) !void {
    var frontier = PQ(NC, void, compNc).init(gpa, {});
    defer frontier.deinit();

    try frontier.add(NC{ .n = name, .c = 0, .p = .{ undefined, undefined, undefined } });

    while (frontier.removeOrNull()) |*cur| {
        if (cur.c == 3 and mem.eql(u8, &name, &cur.n)) {
            try paths.append(cur.p);
        }
        if (cur.c == 3) continue;

        const link = links.get(cur.n).?;
        for (link.items) |other| {
            var p = cur.p;
            p[cur.c] = other;
            try frontier.add(NC{ .n = other, .c = cur.c + 1, .p = p });
        }
    }
}

fn findInter(links: *LinksH) !void {
    var frontier = ArrayList(State).init(gpa);
    defer frontier.deinit();

    {
        var kiter = links.keyIterator();
        while (kiter.next()) |n| {
            var initial = ArrayList(Name).init(gpa);
            try initial.append(n.*);
            try frontier.append(State{ .list = initial });
        }
    }

    var visited = StringHashMap(void).init(gpa);
    defer visited.deinit();

    var list = ArrayList(ArrayList(Name)).init(gpa);

    while (frontier.popOrNull()) |cur| {
        var expandable = AutoHashMap(Name, void).init(gpa);
        defer expandable.deinit();

        defer cur.list.deinit();

        for (cur.list.items) |n| {
            const link = links.get(n).?;

            var kiter = link.keyIterator();
            outer: while (kiter.next()) |other| {
                const link_other = links.get(other.*).?;
                for (cur.list.items) |c| {
                    if (!link_other.contains(c)) {
                        continue :outer;
                    }
                }
                try expandable.put(other.*, {});
            }
        }

        if (expandable.count() == 0) {
            try list.append(try cur.list.clone());
            continue;
        }

        var kiter = expandable.keyIterator();
        while (kiter.next()) |other| {
            var new_list = ArrayList(Name).init(gpa);
            try new_list.appendSlice(cur.list.items);
            try new_list.append(other.*);
            mem.sort(Name, new_list.items, {}, cmpName);

            const size = new_list.items.len * 2;
            const text = try gpa.alloc(u8, size);

            var idx: usize = 0;
            for (new_list.items) |i| {
                text[idx] = i[0];
                text[idx + 1] = i[1];
                idx += 2;
            }

            if (!visited.contains(text)) {
                try visited.put(text, {});
                try frontier.append(State{ .list = new_list });
            }
        }
    }

    var max: usize = 0;
    var maxl: *ArrayList(Name) = undefined;
    for (list.items) |*l| {
        if (l.items.len > max) {
            max = max;
            maxl = l;
        }
        max = @max(max, l.items.len);
    }

    mem.sort(Name, maxl.items, {}, cmpName);

    for (maxl.items) |x| {
        std.debug.print("{s},", .{x});
    }
    std.debug.print("\n", .{});
}

fn cmpName(_: void, a: Name, b: Name) bool {
    return std.mem.order(u8, &a, &b) == math.Order.lt;
}

fn p1(text: Str) !usize {
    var line_iter = mem.split(u8, text, "\n");

    var links = Links.init(gpa);
    defer links.deinit();

    while (line_iter.next()) |line| {
        var name_iter = mem.tokenize(u8, line, "-");
        const name_a = name_iter.next().?[0..2].*;
        const name_b = name_iter.next().?[0..2].*;

        var gop = try links.getOrPutValue(name_a, ArrayList(Name).init(gpa));
        try gop.value_ptr.append(name_b);

        gop = try links.getOrPutValue(name_b, ArrayList(Name).init(gpa));
        try gop.value_ptr.append(name_a);
    }

    var kiter = links.keyIterator();

    var threes = AutoHashMap(Path3Str, void).init(gpa);
    defer threes.deinit();

    while (kiter.next()) |name| {
        var paths = ArrayList(Path3).init(gpa);
        defer paths.deinit();
        try find3(&links, name.*, &paths);

        for (paths.items) |three| {
            for (three) |n| {
                if (n[0] == 't') {
                    var s = three;
                    var buf: Path3Str = undefined;
                    mem.sort(Name, &s, {}, cmpName);
                    _ = try fmt.bufPrint(&buf, "{s}{s}{s}", .{ s[0], s[1], s[2] });
                    try threes.put(buf, {});
                }
            }
        }
    }

    return threes.count();
}

fn p2(text: Str) !void {
    var line_iter = mem.split(u8, text, "\n");

    var links = LinksH.init(gpa);
    defer links.deinit();

    while (line_iter.next()) |line| {
        var name_iter = mem.tokenize(u8, line, "-");
        const name_a = name_iter.next().?[0..2].*;
        const name_b = name_iter.next().?[0..2].*;

        var gop = try links.getOrPutValue(name_a, LSet.init(gpa));
        try gop.value_ptr.put(name_b, {});

        gop = try links.getOrPutValue(name_b, LSet.init(gpa));
        try gop.value_ptr.put(name_a, {});
    }

    try findInter(&links);
}

pub fn main() anyerror!void {
    // defer _ = gpa_impl.deinit();
    const text = if (tst) @embedFile("test") else @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
