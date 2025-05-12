const std = @import("std");
const RegularExpression = @import("regexp.zig").RegularExpression;

pub const RegularExpressionFormatter = struct {
    const Self = @This();

    fn printToWriter(r: *const RegularExpression, writer: std.io.AnyWriter) !void {
        switch (r.*) {
            .Zero => try writer.writeAll("∅"),
            .One => try writer.writeAll("ε"),
            .Char => |case| try writer.print("{c}", .{case.c}),
            .Alt => |case| {
                try writer.writeAll("(");
                try Self.printToWriter(case.r_1, writer);
                try writer.writeAll("|");
                try Self.printToWriter(case.r_2, writer);
                try writer.writeAll(")");
            },
            .Seq => |case| {
                try writer.writeAll("(");
                try Self.printToWriter(case.r_1, writer);
                try Self.printToWriter(case.r_2, writer);
                try writer.writeAll(")");
            },
            .Star => |case| {
                try writer.writeAll("(");
                try Self.printToWriter(case.r, writer);
                try writer.writeAll(")");
                try writer.writeAll("*");
            },
            .Range => |case| {
                try writer.writeAll("[");
                for (0..255) |i| {
                    if (case.bitset.isSet(i)) try writer.print("{c}", .{@as(u8, @intCast(i))});
                }
                try writer.writeAll("]");
            },
            .Plus => |case| {
                try writer.writeAll("(");
                try Self.printToWriter(case.r, writer);
                try writer.writeAll(")");
                try writer.writeAll("+");
            },
            .Optional => |case| {
                try writer.writeAll("(");
                try Self.printToWriter(case.r, writer);
                try writer.writeAll(")");
                try writer.writeAll("?");
            },
            .NTimes => |case| {
                try Self.printToWriter(case.r, writer);
                try writer.print("{{{d}}}", .{case.n});
            },
            .Upto => |case| {
                try Self.printToWriter(case.r, writer);
                try writer.print("{{0,{d}}}", .{case.n});
            },
            .From => |case| {
                try Self.printToWriter(case.r, writer);
                try writer.print("{{{d},}}", .{case.n});
            },
            .Between => |case| {
                try Self.printToWriter(case.r, writer);
                try writer.print("{{{d},{d}}}", .{ case.n, case.m });
            },
            .Not => |case| {
                try writer.writeAll("^");
                try writer.writeAll("(");
                try Self.printToWriter(case.r, writer);
                try writer.writeAll(")");
            },
        }
    }

    pub fn format(r: *const RegularExpression, allocator: std.mem.Allocator) ![]const u8 {
        var buffer = std.ArrayList(u8).init(allocator);
        defer buffer.deinit();

        const writer = buffer.writer().any();
        try RegularExpressionFormatter.printToWriter(r, writer);
        return try buffer.toOwnedSlice();
    }
};
