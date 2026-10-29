const std = @import("std");

const ParseUnsignedError = error{
    ValueTooSmall,
    ValueTooLarge,
} || std.fmt.ParseIntError;

const ansi = struct {
    const reset = "\x1b[0m";
    const bold = "\x1b[1m";
    const cyan = "\x1b[36m";
    const magenta = "\x1b[35m";
    const green = "\x1b[32m";
    const yellow = "\x1b[33m";
    const blue = "\x1b[34m";
    const white = "\x1b[97m";
};

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;

    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len <= 1) {
        try runShowcase(allocator, init.io);
        return;
    }

    const command = args[1];

    if (std.mem.eql(u8, command, "help")) {
        printHelp();
        return;
    }

    if (std.mem.eql(u8, command, "sierpinski")) {
        const rows = if (args.len >= 3)
            parseBoundedUsize(args[2], 4, 256) catch |err| {
                std.debug.print("Unable to parse rows '{s}': {s}\n", .{ args[2], @errorName(err) });
                return;
            }
        else
            32;

        const glyph: u8 = if (args.len >= 4 and args[3].len > 0) args[3][0] else '*';
        printSierpinski(rows, glyph);
        return;
    }

    if (std.mem.eql(u8, command, "collatz")) {
        if (args.len < 3) {
            std.debug.print("Provide a positive starting value for the Collatz demo.\n", .{});
            return;
        }

        const start = parsePositiveU64(args[2]) catch |err| {
            std.debug.print("Unable to parse start '{s}': {s}\n", .{ args[2], @errorName(err) });
            return;
        };

        printCollatzSummary(start);
        return;
    }

    if (std.mem.eql(u8, command, "walk")) {
        const steps = if (args.len >= 3)
            parseBoundedUsize(args[2], 4, 512) catch |err| {
                std.debug.print("Unable to parse steps '{s}': {s}\n", .{ args[2], @errorName(err) });
                return;
            }
        else
            48;

        try printRandomWalk(allocator, init.io, steps);
        return;
    }

    std.debug.print("Unknown command: {s}\n\n", .{command});
    printHelp();
}

fn runShowcase(allocator: std.mem.Allocator, io: std.Io) !void {
    std.debug.print("{s}{s}╭──────────────── Zig Cosmic Showcase ────────────────╮{s}\n", .{ ansi.magenta, ansi.bold, ansi.reset });
    std.debug.print("{s}  fractals, math, collatz, and a jittery random walk{s}\n", .{ ansi.cyan, ansi.reset });
    std.debug.print("{s}  boot sequence: prism -> arithmetic -> comet -> drift{s}\n", .{ ansi.white, ansi.reset });

    printSierpinski(24, '*');

    const example_add = add(42, 58);
    const example_multiply = multiply(13, 37);
    const example_factorial = factorial(10);

    std.debug.print("\n{s}Math glow{s}\n", .{ ansi.magenta, ansi.reset });
    std.debug.print("  add(42, 58)      -> {s}{d}{s}\n", .{ ansi.green, example_add, ansi.reset });
    std.debug.print("  multiply(13, 37) -> {s}{d}{s}\n", .{ ansi.green, example_multiply, ansi.reset });
    std.debug.print("  factorial(10)    -> {s}{d}{s}\n", .{ ansi.green, example_factorial, ansi.reset });

    printCollatzSummary(27);
    try printRandomWalk(allocator, io, 32);
}

fn printSierpinski(rows: usize, glyph: u8) void {
    const safe_rows = if (rows < 2) 2 else rows;
    std.debug.print(
        "\n{s}Sierpinski prism{s} via Pascal mod 2 ({s}rows{s} = {d}, {s}glyph{s} = '{c}'):\n\n",
        .{ ansi.magenta, ansi.reset, ansi.cyan, ansi.reset, safe_rows, ansi.cyan, ansi.reset, glyph },
    );

    var row: usize = 0;
    while (row < safe_rows) : (row += 1) {
        var padding: usize = safe_rows - row;
        while (padding > 0) : (padding -= 1) {
            std.debug.print(" ", .{});
        }

        var col: usize = 0;
        while (col <= row) : (col += 1) {
            if ((row & col) == col) {
                const color = if ((row & 1) == 0) ansi.cyan else ansi.magenta;
                std.debug.print("{s}{c}{s} ", .{ color, glyph, ansi.reset });
            } else {
                std.debug.print("  ", .{});
            }
        }

        std.debug.print("\n", .{});
    }
}

fn printCollatzSummary(start_value: u64) void {
    std.debug.print("\n{s}Collatz comet trail{s} starting at {s}{d}{s}:\n", .{ ansi.magenta, ansi.reset, ansi.yellow, start_value, ansi.reset });

    var value = start_value;
    var steps: usize = 0;
    var max_value: u64 = value;

    while (value != 1) {
        value = collatzNext(value);
        if (value > max_value) {
            max_value = value;
        }
        steps += 1;
    }

    std.debug.print("  {s}Steps to 1{s}: {s}{d}{s}\n  {s}Peak value{s}: {s}{d}{s}\n", .{ ansi.cyan, ansi.reset, ansi.green, steps, ansi.reset, ansi.cyan, ansi.reset, ansi.green, max_value, ansi.reset });

    std.debug.print("  {s}Sample path{s}: ", .{ ansi.cyan, ansi.reset });
    value = start_value;
    var printed: usize = 0;
    var path_meter: usize = 0;
    while (true) {
        if (printed == 24 and value != 1) {
            std.debug.print("... -> 1\n", .{});
            break;
        }

        std.debug.print("{s}{d}{s}", .{ ansi.yellow, value, ansi.reset });
        printed += 1;

        if (value == 1) {
            std.debug.print("\n", .{});
            break;
        }

        std.debug.print(" -> ", .{});
        value = collatzNext(value);
        path_meter += 1;
    }
    std.debug.print("  {s}Trail heat{s}: ", .{ ansi.cyan, ansi.reset });
    var i: usize = 0;
    const heat = if (path_meter == 0) 1 else @min(path_meter / 3 + 1, 24);
    while (i < heat) : (i += 1) {
        std.debug.print("{s}*{s}", .{ ansi.magenta, ansi.reset });
    }
    std.debug.print("\n", .{});
}

fn collatzNext(n: u64) u64 {
    if ((n & 1) == 0) {
        return n / 2;
    }
    return 3 * n + 1;
}

fn printRandomWalk(allocator: std.mem.Allocator, io: std.Io, steps: usize) !void {
    const bounded_steps = if (steps < 4) 4 else steps;
    const now_ms = std.Io.Timestamp.now(io, .real).toMilliseconds();
    const seed: u64 = if (now_ms >= 0) @intCast(now_ms) else @intCast(-now_ms);
    var rng = Random64.init(seed);

    var position: i32 = 0;
    var min_pos: i32 = 0;
    var max_pos: i32 = 0;

    const total_positions = bounded_steps + 1;
    var positions = try allocator.alloc(i32, total_positions);
    defer allocator.free(positions);
    positions[0] = position;
    var filled: usize = 1;

    var step: usize = 0;
    while (step < bounded_steps) : (step += 1) {
        const dir: i32 = if (rng.boolean()) 1 else -1;
        position += dir;
        if (position < min_pos) min_pos = position;
        if (position > max_pos) max_pos = position;
        positions[filled] = position;
        filled += 1;
    }

    std.debug.print("\n{s}Random walk neon track{s} ({s}{d}{s} steps):\n", .{ ansi.magenta, ansi.reset, ansi.yellow, bounded_steps, ansi.reset });

    var index: usize = 0;
    while (index < filled) : (index += 1) {
        const pos = positions[index];
        var column = min_pos;
        while (column <= max_pos) : (column += 1) {
            if (column == pos) {
                std.debug.print("{s}@{s}", .{ ansi.green, ansi.reset });
            } else if (column == 0) {
                std.debug.print("{s}|{s}", .{ ansi.yellow, ansi.reset });
            } else {
                std.debug.print("{s}.{s}", .{ ansi.blue, ansi.reset });
            }
        }
        std.debug.print("  {s}step{s} {d}\n", .{ ansi.cyan, ansi.reset, index });
    }

    const span_width: usize = @intCast((max_pos - min_pos) + 1);
    std.debug.print(
        "{s}Visited span{s}: {d} .. {d} ({s}width{s} {d})\n{s}Ending position{s}: {d}\n",
        .{ ansi.cyan, ansi.reset, min_pos, max_pos, ansi.cyan, ansi.reset, span_width, ansi.cyan, ansi.reset, position },
    );
}

const Random64 = struct {
    state: u64,

    pub fn init(seed: u64) Random64 {
        const mixed = if (seed == 0) 0x9E3779B97F4A7C15 else seed;
        return .{ .state = mixed };
    }

    pub fn next(self: *Random64) u64 {
        var x = self.state;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.state = x;
        return x *% 0x2545F4914F6CDD1D;
    }

    pub fn boolean(self: *Random64) bool {
        return (self.next() & 1) == 1;
    }
};

fn parseBoundedUsize(text: []const u8, min_value: usize, max_value: usize) ParseUnsignedError!usize {
    const value = try std.fmt.parseUnsigned(usize, text, 10);
    if (value < min_value) return error.ValueTooSmall;
    if (value > max_value) return error.ValueTooLarge;
    return value;
}

fn parsePositiveU64(text: []const u8) ParseUnsignedError!u64 {
    const value = try std.fmt.parseUnsigned(u64, text, 10);
    if (value == 0) return error.ValueTooSmall;
    return value;
}

fn printHelp() void {
    std.debug.print(
        "{s}========================================{s}\n" ++
            "{s} Zig Cosmic Playground Help{s}\n" ++
            "{s}========================================{s}\n" ++
            "Usage: zig run main.zig -- [command] [args...]\n\n" ++
            "Commands:\n" ++
            "  help                  Show this help and exit\n" ++
            "  sierpinski [rows] [c]  Render the classic triangle with optional rows/glyph\n" ++
            "  collatz <start>        Explore the Collatz sequence for a starting value\n" ++
            "  walk [steps]           Simulate a random walk with ASCII visualization\n\n" ++
            "Run with no command to launch the full showcase.\n",
        .{ ansi.magenta, ansi.reset, ansi.bold, ansi.reset, ansi.magenta, ansi.reset },
    );
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

pub fn factorial(n: u32) u32 {
    if (n == 0) return 1;
    return n * factorial(n - 1);
}
