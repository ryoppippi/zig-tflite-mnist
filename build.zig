const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    ensureSubmodules(b.allocator) catch |err| @panic(@errorName(err));

    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-tflite-mnist", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    addPkgs(exe);
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

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

fn addPkgs(exe: *std.build.LibExeObjStep) void {
    // add tflite
    if (builtin.os.tag != .windows) {
        exe.addIncludeDir("/usr/local/include");
        exe.addLibraryPath("/usr/local/lib");
    }
    exe.linkSystemLibrary("tensorflowlite_c");
    exe.linkSystemLibrary("c");
    exe.addPackage(tflitePkg);

    // add stb
    exe.addIncludeDir("libs/stb");
}

var tflitePkg = std.build.Pkg{
    .name = "zig-tflite",
    .source = std.build.FileSource{ .path = "libs/zig-tflite/src/main.zig" },
};

fn ensureSubmodules(allocator: std.mem.Allocator) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", "--recursive" }, allocator);
    child.cwd = thisDir();
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();
    _ = try child.spawnAndWait();
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
