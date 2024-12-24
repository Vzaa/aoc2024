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

const Inputs = StringHashMap(u1);

const Op = enum {
    Or,
    And,
    Xor,

    fn fromStr(text: Str) Op {
        if (mem.eql(u8, text, "OR")) {
            return Op.Or;
        } else if (mem.eql(u8, text, "AND")) {
            return Op.And;
        } else if (mem.eql(u8, text, "XOR")) {
            return Op.Xor;
        } else {
            unreachable;
        }
    }

    fn exe(self: *const Op, a: u1, b: u1) u1 {
        return switch (self.*) {
            Op.Or => a | b,
            Op.And => a & b,
            Op.Xor => a ^ b,
        };
    }
};

const Circuit = struct {
    a: Str,
    b: Str,
    out: Str,
    op: Op,

    fn fromStr(text: Str) !Circuit {
        var it = mem.tokenize(u8, text, " ->");
        const a = it.next().?;
        const op = Op.fromStr(it.next().?);
        const b = it.next().?;
        const out = it.next().?;

        return Circuit{ .a = a, .b = b, .out = out, .op = op };
    }
};

fn parseInputs(text: Str) !Inputs {
    var inputs = Inputs.init(gpa);

    var lines = mem.tokenize(u8, text, "\n");

    while (lines.next()) |line| {
        var it = mem.tokenize(u8, line, " :");
        const name = it.next().?;
        const val = try fmt.parseInt(u1, it.next().?, 2);

        try inputs.put(name, val);
    }

    return inputs;
}

fn parseCircuit(text: Str) !ArrayList(Circuit) {
    var circuits = ArrayList(Circuit).init(gpa);

    var lines = mem.tokenize(u8, text, "\n");

    while (lines.next()) |line| {
        const c = try Circuit.fromStr(line);

        try circuits.append(c);
    }

    return circuits;
}

fn p1(text: Str) !u64 {
    var parts = mem.split(u8, text, "\n\n");
    const part_a = parts.next().?;
    const part_b = parts.next().?;

    var inputs = try parseInputs(part_a);
    defer inputs.deinit();

    var circuits = try parseCircuit(part_b);
    defer circuits.deinit();

    if (false) {
        var it = inputs.iterator();
        while (it.next()) |e| {
            std.debug.print("{s} {}\n", .{ e.key_ptr.*, e.value_ptr.* });
        }

        for (circuits.items) |c| {
            std.debug.print("{s} {} {s} {s}\n", .{ c.a, c.op, c.b, c.out });
        }
    }

    return try solve(circuits.items, &inputs);
}

fn getValue(c: u8, inputs: *const Inputs) !u64 {
    var val: u64 = 0;
    for (0..99) |i| {
        var buf: [3]u8 = undefined;
        _ = try fmt.bufPrint(&buf, "{c}{d:0>2}", .{ c, i });
        if (inputs.get(&buf)) |z| {
            const z64: u64 = @intCast(z);
            val |= (z64 << @intCast(i));
        } else {
            break;
        }
    }

    return val;
}

fn setValue(x: u64, y: u64) !Inputs {
    var inputs = Inputs.init(gpa);

    for (0..45) |i| {
        const one: u64 = 1;
        const xb = x & (one << @intCast(i));
        const yb = y & (one << @intCast(i));

        var buf = try fmt.allocPrint(gpa, "x{d:0>2}", .{i});
        try inputs.put(buf, if (xb == 0) 0 else 1);

        buf = try fmt.allocPrint(gpa, "y{d:0>2}", .{i});
        try inputs.put(buf, if (yb == 0) 0 else 1);
    }

    return inputs;
}

fn solve(circuits: []const Circuit, inputs: *const Inputs) !u64 {
    var wires = try inputs.clone();
    defer wires.deinit();

    var out_lut = StringHashMap(*const Circuit).init(gpa);
    defer out_lut.deinit();
    for (circuits) |*c| {
        try out_lut.put(c.out, c);
    }

    var frontier = ArrayList(Str).init(gpa);
    defer frontier.deinit();

    for (circuits) |c| {
        try frontier.append(c.out);
    }

    while (frontier.popOrNull()) |o| {
        const c = out_lut.get(o).?;
        if (!wires.contains(c.a) or !wires.contains(c.b)) {
            // rip
            try frontier.insert(0, o);
            continue;
        }

        const v = c.op.exe(wires.get(c.a).?, wires.get(c.b).?);

        try wires.put(o, v);
    }

    return try getValue('z', &wires);
}

fn getTree(out_lut: *StringHashMap(*const Circuit), out: Str, list: *ArrayList(Str)) !void {
    if (out[0] != 'x' and out[0] != 'y') try list.append(out);
    const c = out_lut.get(out) orelse return;
    try getTree(out_lut, c.a, list);
    try getTree(out_lut, c.b, list);
}

fn swap(circuits: []Circuit, a: Str, b: Str) void {
    for (circuits) |*ca| {
        if (mem.eql(u8, a, ca.out)) {
            for (circuits) |*cb| {
                if (mem.eql(u8, b, cb.out)) {
                    const tmp = ca.out;
                    ca.out = cb.out;
                    cb.out = tmp;
                }
            }
        }
    }
}

fn cmpStr(_: void, a: Str, b: Str) bool {
    return std.mem.order(u8, a, b) == math.Order.lt;
}

fn p2(text: Str) !u64 {
    var parts = mem.split(u8, text, "\n\n");
    const part_a = parts.next().?;
    const part_b = parts.next().?;

    var circuits = try parseCircuit(part_b);
    defer circuits.deinit();

    swap(circuits.items, "vvr", "z08");
    swap(circuits.items, "bkr", "rnq");
    swap(circuits.items, "z28", "tfb");
    swap(circuits.items, "mqh", "z39");

    var out_lut = StringHashMap(*const Circuit).init(gpa);
    defer out_lut.deinit();

    for (circuits.items) |*c| {
        try out_lut.put(c.out, c);
    }

    var tree = ArrayList(Str).init(gpa);
    defer tree.deinit();

    var safe = StringHashMap(void).init(gpa);
    defer safe.deinit();
    try getTree(&out_lut, "z00", &tree);
    try getTree(&out_lut, "z01", &tree);
    try getTree(&out_lut, "z02", &tree);
    try getTree(&out_lut, "z03", &tree);
    try getTree(&out_lut, "z04", &tree);
    try getTree(&out_lut, "z05", &tree);
    try getTree(&out_lut, "z06", &tree);
    try getTree(&out_lut, "z07", &tree);
    try getTree(&out_lut, "z08", &tree);
    try getTree(&out_lut, "z09", &tree);
    try getTree(&out_lut, "z10", &tree);
    try getTree(&out_lut, "z11", &tree);
    try getTree(&out_lut, "z12", &tree);
    try getTree(&out_lut, "z13", &tree);
    try getTree(&out_lut, "z14", &tree);
    try getTree(&out_lut, "z15", &tree);
    try getTree(&out_lut, "z16", &tree);
    try getTree(&out_lut, "z17", &tree);
    try getTree(&out_lut, "z18", &tree);
    try getTree(&out_lut, "z19", &tree);
    try getTree(&out_lut, "z20", &tree);
    try getTree(&out_lut, "z21", &tree);
    try getTree(&out_lut, "z22", &tree);
    try getTree(&out_lut, "z23", &tree);
    try getTree(&out_lut, "z24", &tree);
    try getTree(&out_lut, "z25", &tree);
    try getTree(&out_lut, "z26", &tree);
    try getTree(&out_lut, "z27", &tree);

    for (tree.items) |t| try safe.put(t, {});

    std.debug.print("{}\n", .{safe.count()});

    tree.clearRetainingCapacity();

    try getTree(&out_lut, "z28", &tree);

    for (tree.items) |t| {
        if (!safe.contains(t)) std.debug.print("{s}, ", .{t});
    }
    std.debug.print("\n", .{});

    {
        var inputs = try parseInputs(part_a);
        defer inputs.deinit();

        const x = try getValue('x', &inputs);
        const y = try getValue('y', &inputs);

        const expected = x + y;

        const actual = try solve(circuits.items, &inputs);

        for (0..64) |i| {
            const one: u64 = 1;
            const a = actual & (one << @intCast(i));
            const b = expected & (one << @intCast(i));

            if (a != b) {
                std.debug.print("bit {} wrong\n", .{i});
            }
        }
    }

    var list: [8]Str = .{
        "vvr", "z08",
        "bkr", "rnq",
        "z28", "tfb",
        "mqh", "z39",
    };

    mem.sort(Str, list[0..], {}, cmpStr);
    for (list) |a| std.debug.print("{s},", .{a});
    std.debug.print("\n", .{});

    if (true) return 0;

    const limit: u64 = 1 << 44;

    for ((limit / 4) - 1..limit) |xx| {
        std.debug.print("{b}\n", .{xx});
        // for (0..limit) |yy| {
        for ((limit / 4) - 1..limit) |yy| {
            var inputs = try setValue(xx, yy);
            defer inputs.deinit();

            const x = try getValue('x', &inputs);
            const y = try getValue('y', &inputs);

            const expected = x + y;

            const actual = try solve(circuits.items, &inputs);

            for (0..64) |i| {
                const one: u64 = 1;
                const a = actual & (one << @intCast(i));
                const b = expected & (one << @intCast(i));

                if (a != b) {
                    std.debug.print("bit {} wrong\n", .{i});
                }
            }
        }
    }

    // std.debug.print("{} {} {}\n", .{ x, y, x + y });
    // x: 34347497629091 y: 23741730537165 exp: 58089228166256

    return 0;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = if (tst) @embedFile("test") else @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
