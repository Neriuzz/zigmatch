const std = @import("std");
const RegularExpression = @import("regexp.zig").RegularExpression;
const Range = @import("regexp.zig").Range;
const Allocator = std.mem.Allocator;

pub const RegularExpressionBuilder = struct {
    allocator: Allocator,

    pub fn init(allocator: Allocator) RegularExpressionBuilder {
        return .{ .allocator = allocator };
    }

    pub fn zero(self: RegularExpressionBuilder) *const RegularExpression {
        return self.make(.{ .Zero = .{} });
    }

    pub fn one(self: RegularExpressionBuilder) *const RegularExpression {
        return self.make(.{ .One = .{} });
    }

    pub fn char(self: RegularExpressionBuilder, c: u8) *const RegularExpression {
        return self.make(.{ .Char = .{ .c = c } });
    }

    pub fn alt(self: RegularExpressionBuilder, r_1: *const RegularExpression, r_2: *const RegularExpression) *const RegularExpression {
        return self.make(.{ .Alt = .{ .r_1 = r_1, .r_2 = r_2 } });
    }

    pub fn seq(self: RegularExpressionBuilder, r_1: *const RegularExpression, r_2: *const RegularExpression) *const RegularExpression {
        return self.make(.{ .Seq = .{ .r_1 = r_1, .r_2 = r_2 } });
    }

    pub fn star(self: RegularExpressionBuilder, r: *const RegularExpression) *const RegularExpression {
        return self.make(.{ .Star = .{ .r = r } });
    }

    pub fn range(self: RegularExpressionBuilder, comptime cs: []const u8) *const RegularExpression {
        return self.make(.{ .Range = Range.init(cs) });
    }

    pub fn plus(self: RegularExpressionBuilder, r: *const RegularExpression) *const RegularExpression {
        return self.make(.{ .Plus = .{ .r = r } });
    }

    pub fn optional(self: RegularExpressionBuilder, r: *const RegularExpression) *const RegularExpression {
        return self.make(.{ .Optional = .{ .r = r } });
    }

    pub fn ntimes(self: RegularExpressionBuilder, r: *const RegularExpression, n: u32) *const RegularExpression {
        return self.make(.{ .NTimes = .{ .r = r, .n = n } });
    }

    pub fn upto(self: RegularExpressionBuilder, r: *const RegularExpression, n: u32) *const RegularExpression {
        return self.make(.{ .Upto = .{ .r = r, .n = n } });
    }

    pub fn from(self: RegularExpressionBuilder, r: *const RegularExpression, n: u32) *const RegularExpression {
        return self.make(.{ .From = .{ .r = r, .n = n } });
    }

    pub fn between(self: RegularExpressionBuilder, r: *const RegularExpression, n: u32, m: u32) *const RegularExpression {
        return self.make(.{ .Between = .{ .r = r, .n = n, .m = m } });
    }

    pub fn not(self: RegularExpressionBuilder, r: *const RegularExpression) *const RegularExpression {
        return self.make(.{ .Not = .{ .r = r } });
    }

    fn make(self: RegularExpressionBuilder, value: RegularExpression) *const RegularExpression {
        const result = self.allocator.create(RegularExpression) catch @panic("Out of memory");
        result.* = value;
        return result;
    }
};
