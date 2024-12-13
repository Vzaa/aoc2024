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
const Point = [2]u64;

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    return math.order(a.c, b.c);
}

fn gcd(a: u64, b: u64) u64 {
    if (a == 0) {
        return b;
    } else {
        return gcd(b % a, a);
    }
}

fn lcm(a: u64, b: u64) u64 {
    if (a == 0 or b == 0) {
        return 0;
    } else {
        return (a * b) / gcd(a, b);
    }
}

const PC = struct {
    p: Point,
    c: usize,
};

const Machine = struct {
    prize: Point,
    button_a: Point,
    button_b: Point,

    fn parse_btn(text: Str) !Point {
        var parts = mem.tokenize(u8, text, " ");
        _ = parts.next().?;
        _ = parts.next().?;
        const x_str = parts.next().?;
        const y_str = parts.next().?;
        const x = try fmt.parseInt(u64, x_str[2..(x_str.len - 1)], 10);
        const y = try fmt.parseInt(u64, y_str[2..], 10);
        return .{ x, y };
    }

    fn parse_prize(text: Str) !Point {
        var parts = mem.tokenize(u8, text, " ");
        _ = parts.next().?;
        const x_str = parts.next().?;
        const y_str = parts.next().?;
        const x = try fmt.parseInt(u64, x_str[2..(x_str.len - 1)], 10);
        const y = try fmt.parseInt(u64, y_str[2..], 10);
        return .{ x, y };
    }

    fn parse(text: Str) !Machine {
        var lines = mem.split(u8, text, "\n");

        const btn_a_txt = lines.next().?;
        const btn_b_txt = lines.next().?;
        const prize_txt = lines.next().?;

        const a = try parse_btn(btn_a_txt);
        const b = try parse_btn(btn_b_txt);
        const p = try parse_prize(prize_txt);

        return .{ .prize = p, .button_a = a, .button_b = b };
    }

    fn ucs(self: *const Machine) !usize {
        var frontier = PQ(PC, void, compPc).init(gpa, {});
        defer frontier.deinit();

        const prize = .{ self.prize[0], self.prize[1] };

        var visited = AutoHashMap(Point, usize).init(gpa);
        defer visited.deinit();

        const g_x = gcd(self.button_a[0], self.button_b[0]);
        const g_y = gcd(self.button_a[1], self.button_b[1]);

        if (prize[0] % g_x != 0) return 0;
        if (prize[1] % g_y != 0) return 0;

        try frontier.add(PC{ .p = .{ 0, 0 }, .c = 0 });

        while (frontier.removeOrNull()) |cur| {
            if (cur.p[0] > prize[0]) continue;
            if (cur.p[1] > prize[1]) continue;

            try visited.put(cur.p, cur.c);

            if (cur.p[0] == prize[0] and cur.p[1] == prize[1]) {
                return cur.c;
            }

            {
                const cost = cur.c + 3;
                const np = add(cur.p, self.button_a);
                if (visited.get(np)) |old_c| {
                    if (old_c > cost) {
                        try frontier.add(PC{ .p = np, .c = cost });
                        try visited.put(np, cost);
                    }
                } else {
                    try frontier.add(PC{ .p = np, .c = cost });
                    try visited.put(np, cost);
                }
            }

            {
                const cost = cur.c + 1;
                const np = add(cur.p, self.button_b);
                if (visited.get(np)) |old_c| {
                    if (old_c > cost) {
                        try frontier.add(PC{ .p = np, .c = cost });
                        try visited.put(np, cost);
                    }
                } else {
                    try frontier.add(PC{ .p = np, .c = cost });
                    try visited.put(np, cost);
                }
            }
        }

        return 0;
    }

    fn solve(self: *const Machine, offset: u64) !u64 {
        const prize = .{ self.prize[0] + offset, self.prize[1] + offset };

        var ax = self.button_a[0];
        var ay = self.button_a[1];
        var bx = self.button_b[0];
        var by = self.button_b[1];
        var px = prize[0];
        var py = prize[1];

        const g_x = gcd(ax, bx);
        const g_y = gcd(ay, by);

        if (px % g_x != 0) return 0;
        if (py % g_y != 0) return 0;

        ax /= g_x;
        bx /= g_x;
        px /= g_x;
        ay /= g_y;
        by /= g_y;
        py /= g_y;

        const mx = lcm(ax, ay) / ax;
        const my = lcm(ax, ay) / ay;

        bx *= mx;
        px *= mx;
        by *= my;
        py *= my;

        var d: i64 = 0;
        var p: i64 = 0;
        d = @as(i64, @bitCast(bx)) - @as(i64, @bitCast(by));
        p = @as(i64, @bitCast(px)) - @as(i64, @bitCast(py));
        const dd = @divTrunc(p, d);
        if (dd < 0) return 0;

        const b: u64 = @as(u64, @bitCast(@divTrunc(p, d)));
        if (b * self.button_b[0] > prize[0]) return 0;
        const rem = prize[0] - (b * self.button_b[0]);
        const remy = prize[1] - (b * self.button_b[1]);
        if (rem % self.button_a[0] != 0) return 0;
        if (remy % self.button_a[1] != 0) return 0;
        const a = rem / self.button_a[0];
        return b + a * 3;
    }
};

fn p1(text: Str) !u64 {
    var machines_str = mem.split(u8, text, "\n\n");

    var sum: u64 = 0;
    while (machines_str.next()) |machine_str| {
        const m = try Machine.parse(machine_str);
        sum += try m.ucs();
    }
    return sum;
}

fn p2(text: Str) !u64 {
    var machines_str = mem.split(u8, text, "\n\n");

    var sum: u64 = 0;
    while (machines_str.next()) |machine_str| {
        const m = try Machine.parse(machine_str);

        sum += try m.solve(10000000000000);
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
