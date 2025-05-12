const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{ .name = "lib", .root_source_file = b.path("src/matcher.zig"), .target = target, .optimize = optimize });

    const exe = b.addExecutable(.{ .name = "demo", .root_source_file = b.path("src/demo.zig"), .target = target, .optimize = optimize });

    exe.linkLibrary(lib);
    b.installArtifact(lib);
    b.installArtifact(exe);
}
