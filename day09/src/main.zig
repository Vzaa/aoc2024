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

fn p1(text: Str) !usize {
    var disk = ArrayList(?usize).init(gpa);
    defer disk.deinit();

    var w_iter = mem.window(u8, text, 2, 2);
    var idx: usize = 0;
    while (w_iter.next()) |w| : (idx += 1) {
        const b = try fmt.charToDigit(w[0], 10);
        const buf = [_]?usize{idx} ** 9;
        try disk.appendSlice(buf[0..b]);

        if (w.len == 1) break;

        const f = try fmt.charToDigit(w[1], 10);
        const bufn = [_]?usize{null} ** 9;
        try disk.appendSlice(bufn[0..f]);
    }

    while (true) {
        const idx_empty = mem.indexOf(?usize, disk.items, &[_]?usize{null}).?;
        const idx_last = mem.lastIndexOfNone(?usize, disk.items, &[_]?usize{null}).?;
        if (idx_empty > idx_last) break;
        mem.swap(?usize, &disk.items[idx_last], &disk.items[idx_empty]);
    }

    var sum: usize = 0;
    for (disk.items, 0..) |v, p| {
        if (v == null) break;
        sum += v.? * p;
    }

    return sum;
}

fn p2(text: Str) !usize {
    var disk = ArrayList(?usize).init(gpa);
    defer disk.deinit();

    var w_iter = mem.window(u8, text, 2, 2);
    var idx: usize = 0;
    while (w_iter.next()) |w| : (idx += 1) {
        const b = try fmt.charToDigit(w[0], 10);
        const buf = [_]?usize{idx} ** 9;
        try disk.appendSlice(buf[0..b]);

        if (w.len == 1) break;

        const f = try fmt.charToDigit(w[1], 10);
        const bufn = [_]?usize{null} ** 9;
        try disk.appendSlice(bufn[0..f]);
    }
    var block = idx;
    while (block > 0) : (block -= 1) {
        const pos_left = mem.indexOf(?usize, disk.items, &[_]?usize{block}).?;
        const pos_right = mem.lastIndexOf(?usize, disk.items, &[_]?usize{block}).?;
        const len = pos_right - pos_left + 1;

        var empty_pos: ?usize = null;
        var slice = disk.items[0..pos_left];
        while (true) {
            const empty_left = mem.indexOf(?usize, slice, &[_]?usize{null}) orelse break;
            const empty_len: usize = mem.indexOfNone(?usize, slice[empty_left..], &[_]?usize{null}) orelse slice.len - empty_left;
            if (empty_len >= len) {
                empty_pos = empty_left;
                break;
            }
            slice = slice[empty_left + empty_len ..];
        }
        if (empty_pos) |e| {
            mem.copyForwards(?usize, slice[e .. e + len], disk.items[pos_left .. pos_left + len]);
            const bufn = [_]?usize{null} ** 9;
            mem.copyForwards(?usize, disk.items[pos_left .. pos_left + len], bufn[0..len]);
            continue;
        }
    }

    var sum: usize = 0;
    for (disk.items, 0..) |v, p| {
        if (v == null) continue;
        sum += v.? * p;
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
