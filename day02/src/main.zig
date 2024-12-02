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
    var cnt: u32 = 0;

    var line_iter = mem.tokenize(u8, text, "\n");
    while (line_iter.next()) |line| {
        var list_a = ArrayList(i32).init(gpa);
        defer list_a.deinit();

        var num_iter = mem.tokenize(u8, line, " ");

        while (num_iter.next()) |nstr| {
            const n = try fmt.parseInt(i32, nstr, 10);
            try list_a.append(n);
        }

        if (check_levels(list_a.items)) {
            cnt += 1;
        }
    }

    return cnt;
}

fn p2(text: Str) !u32 {
    var cnt: u32 = 0;

    var line_iter = mem.tokenize(u8, text, "\n");
    while (line_iter.next()) |line| {
        var list_a = ArrayList(i32).init(gpa);
        defer list_a.deinit();

        var num_iter = mem.tokenize(u8, line, " ");

        while (num_iter.next()) |nstr| {
            const n = try fmt.parseInt(i32, nstr, 10);
            try list_a.append(n);
        }

        if (check_levels(list_a.items)) {
            cnt += 1;
        } else {
            // lazy, copy stuff and remove
            for (list_a.items, 0..) |_, idx| {
                var copy = try list_a.clone();
                defer copy.deinit();
                _ = copy.orderedRemove(idx);
                if (check_levels(copy.items)) {
                    cnt += 1;
                    break;
                }
            }
        }
    }

    return cnt;
}

fn check_levels(list: []i32) bool {
    var i: isize = 0;
    var w_iter = mem.window(i32, list, 2, 1);
    var increase: ?bool = null;
    while (w_iter.next()) |nums| : (i += 1) {
        const a = nums[0];
        const b = nums[1];
        if (increase == null) {
            increase = a > b;
        }
        const diff = @abs(a - b);

        if (increase != (a > b) or diff == 0 or diff > 3) {
            break;
        } else if (i == list.len - 2) {
            return true;
        }
    }
    return false;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
