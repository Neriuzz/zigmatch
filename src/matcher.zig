//! Regular expression matching engine that uses Brzozowski derivatives to determine whether a given regular expression matches some string

const std = @import("std");
const testing = std.testing;
const RegularExpression = @import("regexp.zig").RegularExpression;
const RegularExpressionBuilder = @import("builder.zig").RegularExpressionBuilder;
const RegularExpressionFormatter = @import("formatter.zig").RegularExpressionFormatter;
const Timer = std.time.Timer;
const ArenaAllocator = std.heap.ArenaAllocator;

pub const Matcher = struct {
    builder: RegularExpressionBuilder,

    // Represents the empty set.
    zero: *const RegularExpression,

    // Represents the empty string.
    one: *const RegularExpression,

    pub fn init(builder: RegularExpressionBuilder) Matcher {
        return Matcher{ .builder = builder, .zero = builder.zero(), .one = builder.one() };
    }

    // Determines whether a given regular expression can match the empty string
    fn nullable(self: Matcher, r: *const RegularExpression) bool {
        return switch (r.*) {
            .Zero => false,
            .One => true,
            .Char => false,
            .Alt => |case| self.nullable(case.r_1) or self.nullable(case.r_2),
            .Seq => |case| self.nullable(case.r_1) and self.nullable(case.r_2),
            .Star => true,
            .Range => false,
            .Plus => |case| self.nullable(case.r),
            .Optional => true,
            .NTimes => |case| if (case.n == 0) true else self.nullable(case.r),
            .Upto => true,
            .From => |case| if (case.n == 0) true else self.nullable(case.r),
            .Between => |case| if (case.n == 0) true else self.nullable(case.r),
            .Not => |case| !self.nullable(case.r),
        };
    }

    // Calculates the Brzozowski derivative of a given regular expression w.r.t some character
    fn derivative(self: Matcher, r: *const RegularExpression, c: u8) *const RegularExpression {
        return switch (r.*) {
            .Zero => self.zero,
            .One => self.zero,
            .Char => |case| if (case.c == c) self.one else self.zero,
            .Alt => |case| self.builder.alt(self.derivative(case.r_1, c), self.derivative(case.r_2, c)),
            .Seq => |case| if (self.nullable(case.r_1)) self.builder.alt(self.builder.seq(self.derivative(case.r_1, c), case.r_2), self.derivative(case.r_2, c)) else self.builder.seq(self.derivative(case.r_1, c), case.r_2),
            .Star => |case| self.builder.seq(self.derivative(case.r, c), self.builder.star(case.r)),
            .Range => |case| if (case.contains(c)) self.one else self.zero,
            .Plus => |case| self.builder.seq(self.derivative(case.r, c), self.builder.star(case.r)),
            .Optional => |case| self.derivative(case.r, c),
            .NTimes => |case| if (case.n == 0) self.zero else self.builder.seq(self.derivative(case.r, c), self.builder.ntimes(case.r, case.n - 1)),
            .Upto => |case| if (case.n == 0) self.zero else self.builder.seq(self.derivative(case.r, c), self.builder.upto(case.r, case.n - 1)),
            .From => |case| if (case.n == 0) self.derivative(self.builder.star(case.r), c) else self.builder.seq(self.derivative(case.r, c), self.builder.from(case.r, case.n - 1)),
            .Between => |case| if (case.n == 0) self.derivative(self.builder.upto(case.r, case.m), c) else self.builder.seq(self.derivative(case.r, c), self.builder.between(case.r, case.n - 1, case.m - 1)),
            .Not => |case| self.builder.not(self.derivative(case.r, c)),
        };
    }

    // Simplifies a given regular expression
    fn simplify(self: Matcher, r: *const RegularExpression) *const RegularExpression {
        switch (r.*) {
            .Alt => |case| {
                const simp_r_1 = self.simplify(case.r_1);
                const simp_r_2 = self.simplify(case.r_2);

                if (simp_r_1.equals(self.zero)) {
                    return simp_r_2;
                } else if (simp_r_2.equals(self.zero)) {
                    return simp_r_1;
                } else if (simp_r_1.equals(simp_r_2)) {
                    return simp_r_1;
                }
                return self.builder.alt(simp_r_1, simp_r_2);
            },
            .Seq => |case| {
                const simp_r_1 = self.simplify(case.r_1);
                const simp_r_2 = self.simplify(case.r_2);

                if (simp_r_1.equals(self.zero) or simp_r_2.equals(self.zero)) {
                    return self.zero;
                } else if (simp_r_1.equals(self.one)) {
                    return simp_r_2;
                } else if (simp_r_2.equals(self.one)) {
                    return simp_r_1;
                }
                return self.builder.seq(simp_r_1, simp_r_2);
            },
            else => return r,
        }
    }

    fn derivatives(self: Matcher, r: *const RegularExpression, string: []const u8) *const RegularExpression {
        if (string.len == 0) return r;

        return self.derivatives(self.simplify(self.derivative(r, string[0])), string[1..]);
    }

    pub fn match(self: Matcher, r: *const RegularExpression, string: []const u8) bool {
        var timer = Timer.start() catch unreachable;
        defer {
            const elapsed: f64 = @floatFromInt(timer.read());
            const regexpString = RegularExpressionFormatter.format(r, self.builder.allocator) catch unreachable;
            std.debug.print("Matching {s} on {s} took {d:.3}ms\n", .{ regexpString, string, elapsed / std.time.ns_per_ms });
        }

        return self.nullable(self.derivatives(r, string));
    }
};

test "Matcher" {
    var arena = ArenaAllocator.init(testing.allocator);
    const allocator = arena.allocator();
    const builder = RegularExpressionBuilder.init(allocator);
    defer arena.deinit();

    const matcher = Matcher.init(builder);

    //A|B
    var r = builder.alt(builder.char('A'), builder.char('B'));
    try testing.expectEqual(true, matcher.match(r, "A"));
    try testing.expectEqual(true, matcher.match(r, "B"));
    try testing.expectEqual(false, matcher.match(r, "C"));

    //A*
    r = builder.star(builder.char('A'));
    try testing.expectEqual(true, matcher.match(r, "AAA"));
    try testing.expectEqual(true, matcher.match(r, ""));
    try testing.expectEqual(false, matcher.match(r, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB"));

    // A(A|B)
    r = builder.seq(builder.char('A'), builder.alt(builder.char('A'), builder.char('B')));
    try testing.expectEqual(true, matcher.match(r, "AA"));
    try testing.expectEqual(true, matcher.match(r, "AB"));
    try testing.expectEqual(false, matcher.match(r, "AC"));

    // [A, B, C]
    r = builder.range("ABC");
    try testing.expectEqual(true, matcher.match(r, "A"));
    try testing.expectEqual(true, matcher.match(r, "B"));
    try testing.expectEqual(true, matcher.match(r, "C"));

    //AB?C
    r = builder.seq(builder.seq(builder.char('A'), builder.optional(builder.char('B'))), builder.char('C'));
    try testing.expectEqual(true, matcher.match(r, "AC"));
    try testing.expectEqual(true, matcher.match(r, "ABC"));

    //[A, B]*
    r = builder.star(builder.range("AB"));
    try testing.expectEqual(true, matcher.match(r, "AB"));
    try testing.expectEqual(true, matcher.match(r, "ABAB"));
    try testing.expectEqual(true, matcher.match(r, "BABA"));
    try testing.expectEqual(false, matcher.match(r, "CACA"));

    // Email
    r = builder.seq(builder.seq(builder.seq(builder.seq(builder.plus(builder.range("abcdefghijklmnopqrstuvwxyz0123456789_.-")), builder.char('@')), builder.plus(builder.range("abcdefghijklmnopqrstuvwxyz0123456789_.-"))), builder.char('.')), builder.between(builder.range("abcdefghijklmnopqrstuvwxyz0123456789_.-"), 2, 6));
    try testing.expectEqual(true, matcher.match(r, "neriusilmonas@gmail.com"));

    // Evil
    r = builder.plus(builder.plus(builder.seq(builder.seq(builder.char('a'), builder.char('a')), builder.char('a'))));
    try testing.expectEqual(true, matcher.match(r, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"));
    r = builder.plus(builder.plus(builder.seq(builder.between(builder.char('a'), 19, 19), builder.optional(builder.char('a')))));
    try testing.expectEqual(true, matcher.match(r, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"));

    // Very evil
    r = builder.seq(builder.star(builder.alt(builder.char('a'), builder.seq(builder.char('a'), builder.char('a')))), builder.char('c'));
    try testing.expectEqual(false, matcher.match(r, "aaaaaaaaaaaaaaaaaaaaaaaaax"));
}
