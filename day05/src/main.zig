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

// based on mem.trimLeft
pub fn takeLeft(comptime T: type, slice: []const T, values_to_take: []const T) []const T {
    var end: usize = 0;
    while (end < slice.len and mem.indexOfScalar(T, values_to_take, slice[end]) != null) : (end += 1) {}
    return slice[0..end];
}

const Rule = struct {
    a: u32,
    b: u32,
};

fn p1(text: Str) !u32 {
    var split = mem.split(u8, text, "\n\n");
    const rules_str = split.next().?;
    const updates_str = split.next().?;

    var rules = ArrayList(Rule).init(gpa);
    defer rules.deinit();

    var line_iter = mem.tokenize(u8, rules_str, "\n");
    while (line_iter.next()) |line| {
        var num_iter = mem.tokenize(u8, line, "|");
        const a = try fmt.parseInt(u32, num_iter.next().?, 10);
        const b = try fmt.parseInt(u32, num_iter.next().?, 10);
        try rules.append(.{ .a = a, .b = b });
    }

    line_iter = mem.tokenize(u8, updates_str, "\n");

    var sum: u32 = 0;
    outer: while (line_iter.next()) |line| {
        var update = AutoHashMap(u32, usize).init(gpa);
        defer update.deinit();

        const mid_idx = (mem.count(u8, line, ",") + 1) / 2;

        var mid: u32 = undefined;

        var num_iter = mem.tokenize(u8, line, ",");
        var idx: usize = 0;
        while (num_iter.next()) |num| : (idx += 1) {
            const a = try fmt.parseInt(u32, num, 10);
            try update.put(a, idx);
            if (idx == mid_idx) mid = a;
        }

        for (rules.items) |rule| {
            const a = rule.a;
            const b = rule.b;

            if (update.get(a)) |a_idx| {
                if (update.get(b)) |b_idx| {
                    if (a_idx > b_idx) {
                        continue :outer;
                    }
                }
            }
        }
        sum += mid;
    }

    return sum;
}

fn p2(text: Str) !u32 {
    var split = mem.split(u8, text, "\n\n");
    const rules_str = split.next().?;
    const updates_str = split.next().?;

    var rules = ArrayList(Rule).init(gpa);
    defer rules.deinit();

    var line_iter = mem.tokenize(u8, rules_str, "\n");
    while (line_iter.next()) |line| {
        var num_iter = mem.tokenize(u8, line, "|");
        const a = try fmt.parseInt(u32, num_iter.next().?, 10);
        const b = try fmt.parseInt(u32, num_iter.next().?, 10);
        try rules.append(.{ .a = a, .b = b });
    }

    line_iter = mem.tokenize(u8, updates_str, "\n");

    var sum: u32 = 0;
    while (line_iter.next()) |line| {
        var update = AutoHashMap(u32, usize).init(gpa);
        defer update.deinit();

        const mid_idx = (mem.count(u8, line, ",") + 1) / 2;

        var num_iter = mem.tokenize(u8, line, ",");
        var idx: usize = 0;
        while (num_iter.next()) |num| : (idx += 1) {
            const a = try fmt.parseInt(u32, num, 10);
            try update.put(a, idx);
        }

        var fixed = false;
        // yolo
        outer: while (true) {
            for (rules.items) |rule| {
                const a = rule.a;
                const b = rule.b;
                const a_idx = update.get(a) orelse continue;
                const b_idx = update.get(b) orelse continue;
                if (a_idx > b_idx) {
                    try update.put(b, a_idx);
                    try update.put(a, b_idx);
                    fixed = true;
                    continue :outer;
                }
            }
            break;
        }

        if (!fixed) continue;

        var iter = update.iterator();
        while (iter.next()) |e| {
            if (e.value_ptr.* == mid_idx) {
                sum += e.key_ptr.*;
                break;
            }
        }
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
