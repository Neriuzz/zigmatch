// Demo of the Regex matching engine.

const std = @import("std");
const RegularExpressionBuilder = @import("builder.zig").RegularExpressionBuilder;
const Matcher = @import("matcher.zig").Matcher;

pub fn main() !void {

    // Setup builder & matcher.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    const allocator = arena.allocator();
    const builder = RegularExpressionBuilder.init(allocator);
    defer arena.deinit();
    const matcher = Matcher.init(builder);

    // Setup stdout
    const stdout = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout.writer());
    var w = bw.writer();

    // A*
    const regexp = builder.star(builder.char('A'));
    const matches = matcher.match(regexp, "AAA");

    try w.print("{}\n", .{matches});
    try bw.flush();
}
