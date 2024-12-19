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

const Memo = StringHashMap(bool);
const Memo2 = StringHashMap(usize);

fn valid(design: Str, patterns: []const Str, memo: *Memo) !bool {
    if (design.len == 0) return true;

    if (memo.get(design)) |m| return m;

    var works = false;
    for (patterns) |p| {
        if (mem.startsWith(u8, design, p)) {
            const cur = try valid(design[p.len..], patterns, memo);
            works = works or cur;
            if (works) {
                try memo.put(design, true);
                return true;
            }
        }
    }
    try memo.put(design, works);
    return works;
}

fn valid2(design: Str, patterns: []const Str, memo: *Memo2) !usize {
    if (design.len == 0) return 1;

    if (memo.get(design)) |m| return m;

    var cnt: usize = 0;
    for (patterns) |p| {
        if (mem.startsWith(u8, design, p)) {
            const cur = try valid2(design[p.len..], patterns, memo);
            cnt += cur;
            try memo.put(design, cur);
        }
    }
    try memo.put(design, cnt);
    return cnt;
}

fn p1(text: Str) !usize {
    var parts_iter = mem.split(u8, text, "\n\n");

    var patterns = ArrayList(Str).init(gpa);
    defer patterns.deinit();

    var pat_iter = mem.tokenize(u8, parts_iter.next().?, " ,");
    while (pat_iter.next()) |p| {
        try patterns.append(p);
    }

    var lines = mem.tokenize(u8, parts_iter.next().?, "\n");

    var cnt: usize = 0;
    var i: usize = 0;

    var memo = Memo.init(gpa);
    defer memo.deinit();

    while (lines.next()) |line| : (i += 1) {
        if (try valid(line, patterns.items, &memo)) {
            cnt += 1;
        }
    }

    return cnt;
}

fn p2(text: Str) !usize {
    var parts_iter = mem.split(u8, text, "\n\n");

    var patterns = ArrayList(Str).init(gpa);
    defer patterns.deinit();

    var pat_iter = mem.tokenize(u8, parts_iter.next().?, " ,");
    while (pat_iter.next()) |p| {
        try patterns.append(p);
    }

    var lines = mem.tokenize(u8, parts_iter.next().?, "\n");

    var cnt: usize = 0;
    var i: usize = 0;

    var memo = Memo2.init(gpa);
    defer memo.deinit();

    while (lines.next()) |line| : (i += 1) {
        cnt += try valid2(line, patterns.items, &memo);
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
