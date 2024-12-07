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

fn solve(text: Str, tgt: usize) !u64 {
    var line_iter = mem.tokenize(u8, text, "\n");

    var sum: u64 = 0;
    while (line_iter.next()) |line| {
        var num_iter = mem.tokenize(u8, line, " :");
        const val = try fmt.parseInt(u64, num_iter.next().?, 10);

        var list = ArrayList(u64).init(gpa);
        defer list.deinit();

        while (num_iter.next()) |num_str| {
            const n = try fmt.parseInt(u64, num_str, 10);
            try list.append(n);
        }

        const limit = try math.powi(usize, tgt, list.items.len);

        for (0..limit) |iter| {
            var acc = list.items[0];
            for (list.items[1..], 0..) |n, idx| {
                const op = (iter / (try math.powi(usize, tgt, idx))) % tgt;
                if (op == 0) acc += n;
                if (op == 1) acc *= n;
                if (op == 2) {
                    var cp = n;
                    var cnt: u64 = 1;
                    while (cp >= 10) : (cnt += 1) cp /= 10;
                    acc = acc * (try math.powi(u64, 10, cnt)) + n;
                }
            }
            if (acc > val) continue;
            if (acc == val) {
                sum += val;
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
    print("Part 1: {}\n", .{try solve(trimmed, 2)});
    print("Part 2: {}\n", .{try solve(trimmed, 3)});
}
