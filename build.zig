const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-tflite-mnist", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.use_stage1 = true;
    addPkgs(exe);
    exe.step.dependOn(&b.addSystemCommand(&.{ "git", "submodule", "update", "--init", "--recursive" }).step);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);
    exe_tests.use_stage1 = true;
    addPkgs(exe_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

fn addPkgs(exe: *std.build.LibExeObjStep) void {
    // add tflite
    if (builtin.os.tag != .windows) {
        exe.addIncludePath("/usr/local/include");
        exe.addLibraryPath("/usr/local/lib");
    }
    exe.linkSystemLibrary("tensorflowlite_c");
    exe.linkSystemLibrary("c");
    exe.addPackage(tflitePkg);

    // add stb
    exe.addIncludePath("libs/stb");

    // add mallocz
    exe.addIncludePath("libs/mallocz/src");
    exe.addPackage(malloczPkg);
}

const tflitePkg = std.build.Pkg{
    .name = "zig-tflite",
    .source = std.build.FileSource{ .path = "libs/zig-tflite/src/main.zig" },
};

const malloczPkg = std.build.Pkg{
    .name = "mallocz",
    .source = std.build.FileSource{ .path = "libs/mallocz/src/main.zig" },
};

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
