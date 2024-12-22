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

fn mix(a: i64, b: i64) i64 {
    return a ^ b;
}

fn prune(a: i64) i64 {
    return @mod(a, 16777216);
}

fn p1(text: Str) !i64 {
    var line_iter = mem.split(u8, text, "\n");
    var sum: i64 = 0;
    while (line_iter.next()) |line| {
        var secret = try fmt.parseInt(i64, line, 10);

        for (0..2000) |_| {
            secret = prune(mix(secret * 64, secret));
            secret = prune(mix(@divFloor(secret, 32), secret));
            secret = prune(mix(secret * 2048, secret));
        }
        sum += secret;
    }
    return sum;
}

const Seq = ArrayList(i64);
const Seq4 = [4]i64;

fn p2(text: Str) !i64 {
    var line_iter = mem.split(u8, text, "\n");

    var diffs = ArrayList(Seq).init(gpa);
    defer diffs.deinit();
    defer for (diffs.items) |*i| i.deinit();
    var vals = ArrayList(Seq).init(gpa);
    defer vals.deinit();
    defer for (vals.items) |*i| i.deinit();

    while (line_iter.next()) |line| {
        var secret = try fmt.parseInt(i64, line, 10);

        var diff = Seq.init(gpa);
        var val = Seq.init(gpa);

        for (0..2000) |_| {
            const b4 = secret;
            secret = prune(mix(secret * 64, secret));
            secret = prune(mix(@divFloor(secret, 32), secret));
            secret = prune(mix(secret * 2048, secret));

            try diff.append(@mod(secret, 10) - @mod(b4, 10));
            try val.append(@mod(secret, 10));
        }

        try diffs.append(diff);
        try vals.append(val);
    }
    var seqs = AutoHashMap(Seq4, void).init(gpa);
    defer seqs.deinit();

    for (diffs.items) |diff| {
        var w_iter = mem.window(i64, diff.items, 4, 1);
        while (w_iter.next()) |seq| {
            if (seq.len < 4) break;
            const tmp = Seq4{ seq[0], seq[1], seq[2], seq[3] };
            try seqs.put(tmp, {});
        }
    }

    var max: i64 = 0;

    var kiter = seqs.keyIterator();
    while (kiter.next()) |seq| {
        var sum: i64 = 0;

        for (diffs.items, vals.items) |diff, val| {
            const idx = mem.indexOf(i64, diff.items, seq);
            if (idx) |i| {
                sum += val.items[i + 3];
            }
        }
        max = @max(sum, max);
    }

    return max;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = if (tst) @embedFile("test") else @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
