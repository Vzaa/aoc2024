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

fn p1(text: Str) !u32 {
    var list_a = ArrayList(i32).init(gpa);
    defer list_a.deinit();
    var list_b = ArrayList(i32).init(gpa);
    defer list_b.deinit();

    var line_iter = mem.tokenize(u8, text, "\n");
    while (line_iter.next()) |line| {
        var num_iter = mem.tokenize(u8, line, " ");
        const a = try fmt.parseInt(i32, num_iter.next().?, 10);
        const b = try fmt.parseInt(i32, num_iter.next().?, 10);
        try list_a.append(a);
        try list_b.append(b);
    }
    mem.sort(i32, list_a.items, {}, comptime std.sort.desc(i32));
    mem.sort(i32, list_b.items, {}, comptime std.sort.desc(i32));

    var sum: u32 = 0;
    for (list_a.items, list_b.items) |a, b| {
        sum += @abs(a - b);
    }
    return sum;
}

fn p2(text: Str) !u32 {
    var list_a = ArrayList(u32).init(gpa);
    defer list_a.deinit();
    var list_b = ArrayList(u32).init(gpa);
    defer list_b.deinit();

    var line_iter = mem.tokenize(u8, text, "\n");
    while (line_iter.next()) |line| {
        var num_iter = mem.tokenize(u8, line, " ");
        const a = try fmt.parseInt(u32, num_iter.next().?, 10);
        const b = try fmt.parseInt(u32, num_iter.next().?, 10);
        try list_a.append(a);
        try list_b.append(b);
    }

    var sum: u32 = 0;
    // lazy, yolo search every time
    for (list_a.items) |a| {
        const cnt: u32 = @intCast(mem.count(u32, list_b.items, &[_]u32{a}));
        sum += cnt * a;
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
