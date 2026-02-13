const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const strip_opt = b.option(bool, "strip", "Strip debug symbols") orelse false;

    const exe = b.addExecutable(.{
        .name = "packfs",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (optimize != .Debug) exe.root_module.strip = true;

    exe.root_module.strip = strip_opt;
    exe.link_gc_sections = true;
    exe.link_function_sections = true;
    exe.link_data_sections = true;
    b.installArtifact(exe);
}
