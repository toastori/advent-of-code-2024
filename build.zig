const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build exe
    const exe = b.addExecutable(.{
        .name = "aoc2024",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // build run
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // -- args
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Run Step
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_check = b.addExecutable(.{
        .name = "aoc2024",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const check = b.step("check", "Check grammar");
    check.dependOn(&exe_check.step);
}
