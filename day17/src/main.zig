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

const Op = enum {
    Adv,
    Bxl,
    Bst,
    Jnz,
    Bxc,
    Out,
    Bdv,
    Cdv,

    fn fromNum(n: i64) Op {
        if (n == 0) return Op.Adv;
        if (n == 1) return Op.Bxl;
        if (n == 2) return Op.Bst;
        if (n == 3) return Op.Jnz;
        if (n == 4) return Op.Bxc;
        if (n == 5) return Op.Out;
        if (n == 6) return Op.Bdv;
        if (n == 7) return Op.Cdv;
        unreachable;
    }
};

const Regs = struct {
    a: i64 = 0,
    b: i64 = 0,
    c: i64 = 0,

    pc: u32 = 0,

    fn combo(self: *const Regs, o: i64) i64 {
        if (o <= 3) return o;
        if (o == 4) return self.a;
        if (o == 5) return self.b;
        if (o == 6) return self.c;
        unreachable;
    }

    fn run(self: *Regs, memory: []const i64) !bool {
        if (self.pc >= memory.len) return false;
        const op = Op.fromNum(memory[self.pc]);
        const operand = memory[self.pc + 1];

        // std.debug.print("\n{} {any} {}\n", .{ self.pc, op, operand });

        switch (op) {
            Op.Adv => {
                self.a = @divFloor(self.a, try math.powi(i64, 2, self.combo(operand)));
            },
            Op.Bxl => {
                self.b ^= operand;
            },
            Op.Bst => {
                self.b = @mod(self.combo(operand), 8);
            },
            Op.Jnz => {
                if (self.a != 0) {
                    self.pc = @intCast(operand);
                    return true;
                }
            },
            Op.Bxc => {
                self.b ^= self.c;
            },
            Op.Out => {
                const v = @mod(self.combo(operand), 8);
                std.debug.print("{},", .{v});
            },
            Op.Bdv => {
                self.b = @divFloor(self.a, try math.powi(i64, 2, self.combo(operand)));
            },
            Op.Cdv => {
                self.c = @divFloor(self.a, try math.powi(i64, 2, self.combo(operand)));
            },
        }
        self.pc += 2;
        return true;
    }

    fn parse(text: Str) !Regs {
        var line_iter = mem.tokenize(u8, text, "\n");

        var iter = mem.tokenize(u8, line_iter.next().?, " ");

        _ = iter.next().?;
        _ = iter.next().?;
        const a = try fmt.parseInt(i64, iter.next().?, 10);

        iter = mem.tokenize(u8, line_iter.next().?, " ");
        _ = iter.next().?;
        _ = iter.next().?;
        const b = try fmt.parseInt(i64, iter.next().?, 10);

        iter = mem.tokenize(u8, line_iter.next().?, " ");
        _ = iter.next().?;
        _ = iter.next().?;
        const c = try fmt.parseInt(i64, iter.next().?, 10);

        return Regs{ .a = a, .b = b, .c = c };
    }
};

fn p1(text: Str) !u32 {
    var split = mem.split(u8, text, "\n\n");
    var regs = try Regs.parse(split.next().?);
    var siter = mem.tokenize(u8, split.next().?, " ");
    _ = siter.next().?;
    var iter = mem.tokenize(u8, siter.next().?, ",");

    var memory = ArrayList(i64).init(gpa);
    defer memory.deinit();
    while (iter.next()) |n| {
        const v = try fmt.parseInt(i64, n, 10);
        try memory.append(v);
    }

    while (try regs.run(memory.items)) {}
    std.debug.print("\n", .{});

    return 0;
}

fn port(init: i64) !void {
    var a: i64 = init;
    var b: i64 = 0;
    var c: i64 = 0;

    while (a != 0) {
        b = @mod(a, 8);
        b ^= 5;
        c = @divFloor(a, try math.powi(i64, 2, b));
        b ^= 6;
        b ^= c;
        std.debug.print("{},", .{@mod(b, 8)});
        a = @divFloor(a, 8);
    }
    std.debug.print("\n", .{});
}

fn p2(text: Str) !u32 {
    _ = text;
    return 0;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});

    var nums: [16]i64 = [_]i64{0} ** 16;
    nums[0] = 3;
    nums[1] = 0;
    nums[2] = 3;
    nums[3] = 3;

    nums[4] = 0;
    nums[5] = 7;
    nums[6] = 5;

    nums[7] = 0;
    nums[8] = 0;
    nums[9] = 0;

    nums[10] = 0;
    nums[11] = 0;
    nums[12] = 0;
    nums[13] = 0;
    nums[14] = 0;
    nums[15] = 0;

    var be: usize = undefined;

    // manual sliding, cba to make it automated
    if (false) {
        for (0..8) |a| {
            for (0..8) |b| {
                for (0..8) |c| {
                    for (0..8) |d| {
                        for (0..8) |e| {
                            if (true) std.debug.print("{} {} {} {} {}\n", .{ a, b, c, d, e });
                            nums[4] = @intCast(a);
                            nums[5] = @intCast(b);
                            nums[6] = @intCast(c);
                            nums[7] = @intCast(d);
                            nums[8] = @intCast(e);
                            var num: i64 = 0;
                            for (nums, 0..) |v, i| {
                                const pow: i64 = @intCast(nums.len - i - 1);
                                num += v * try math.powi(i64, 2, pow * 3);
                            }
                            be = @intCast(num);
                            std.debug.print("{}:\n", .{num});
                            try port(@intCast(num));
                        }
                    }
                }
            }
        }
    }
    var num: i64 = 0;
    for (nums, 0..) |v, i| {
        const pow: i64 = @intCast(nums.len - i - 1);
        num += v * try math.powi(i64, 2, pow * 3);
    }
    be = @intCast(num);
    try port(@intCast(num));
    // too high 107416748386714
    //          found : 107416732707226:
    if (true) return; // uncomment and grep output

    var e: usize = undefined;
    num = 0;
    nums[7] += 1;
    for (nums, 0..) |v, i| {
        const pow: i64 = @intCast(nums.len - i - 1);
        num += v * try math.powi(i64, 2, pow * 3);
    }
    e = @intCast(num);
    for (be..e) |i| {
        std.debug.print("{}: ", .{i});
        try port(@intCast(i));
    }
}
