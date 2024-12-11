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

const List = AutoHashMap(u64, usize);

fn add(list: *List, v: u64, cnt: usize) !void {
    const gop = try list.getOrPut(v);
    if (gop.found_existing) gop.value_ptr.* += cnt else gop.value_ptr.* = cnt;
}

fn solve(text: Str, limit: usize) !usize {
    var num_iter = mem.tokenize(u8, text, " ");

    var list = AutoHashMap(u64, usize).init(gpa);
    defer list.deinit();

    while (num_iter.next()) |num| {
        try list.put(try fmt.parseInt(u64, num, 10), 1);
    }

    for (0..limit) |_| {
        var list_next = AutoHashMap(u64, usize).init(gpa);

        var iter = list.iterator();
        while (iter.next()) |e| {
            const v = e.key_ptr.*;
            const cnt = e.value_ptr.*;
            if (v == 0) {
                try add(&list_next, 1, cnt);
                continue;
            }

            var len: u64 = 1;
            var cp = v;
            while (cp >= 10) : (len += 1) cp /= 10;
            if (len % 2 == 0) {
                const a = v / (try math.powi(u64, 10, len / 2));
                const b = v % (try math.powi(u64, 10, len / 2));
                try add(&list_next, a, cnt);
                try add(&list_next, b, cnt);
            } else {
                try add(&list_next, v * 2024, cnt);
            }
        }

        list.deinit();
        list = list_next;
    }

    var sum: usize = 0;
    var viter = list.valueIterator();
    while (viter.next()) |c| sum += c.*;

    return sum;
}

fn p1(text: Str) !usize {
    return try solve(text, 25);
}

fn p2(text: Str) !usize {
    return try solve(text, 75);
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
