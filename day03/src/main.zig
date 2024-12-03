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

const mul_str = "mul(";

fn p1(text: Str) !u32 {
    var line_iter = mem.tokenize(u8, text, "\n");
    var sum: u32 = 0;
    while (line_iter.next()) |line| {
        var slice = line[0..];
        while (mem.indexOf(u8, slice, mul_str)) |idx| {
            slice = slice[(idx + mul_str.len)..];
            // this would fail if there were multiple ',' chars like mul(1,1,1)
            const nums = takeLeft(u8, slice, "0123456789,");
            if (slice[nums.len] == ')') { // can error if we end on with something like mul(1,1
                var num_iter = mem.split(u8, nums, ",");
                const a = try fmt.parseInt(u32, num_iter.next().?, 10);
                const b = try fmt.parseInt(u32, num_iter.next().?, 10);
                sum += a * b;
            }
        }
    }
    return sum;
}

fn p2(text: Str) !u32 {
    var line_iter = mem.tokenize(u8, text, "\n");
    var sum: u32 = 0;

    var do = true;
    while (line_iter.next()) |line| {
        var slice = line[0..];
        var pos: usize = 0; // to keep track of our position relative to the beginning
        while (mem.indexOf(u8, slice, mul_str)) |idx| {
            pos += idx + mul_str.len;
            slice = slice[(idx + "mul(".len)..];
            // this would fail if there were multiple ',' chars like mul(1,1,1)
            const nums = takeLeft(u8, slice, "0123456789,");
            if (slice[nums.len] == ')') { // can error if we end on with something like mul(1,1
                // yolo find the latest dos and don'ts from where we are
                const do_idx = mem.lastIndexOf(u8, line[0..pos], "do()") orelse 0;
                const dont_idx = mem.lastIndexOf(u8, line[0..pos], "don't()") orelse 0;
                if (do_idx > dont_idx) do = true;
                if (dont_idx > do_idx) do = false;
                if (!do) continue;
                var num_iter = mem.split(u8, nums, ",");
                const a = try fmt.parseInt(u32, num_iter.next().?, 10);
                const b = try fmt.parseInt(u32, num_iter.next().?, 10);
                sum += a * b;
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
