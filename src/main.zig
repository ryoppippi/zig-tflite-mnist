const std = @import("std");
const ma = @import("malloc.zig");
const tflite = @import("zig-tflite");
const stb = @import("c.zig");

const model_data = @embedFile("models/model.tflite");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    const prog = args.next();
    const img_path = args.next() orelse {
        std.log.err("usage: {s} [filename]", .{prog.?});
        std.os.exit(1);
    };
    try mainI(img_path, allocator);
}

pub fn mainI(img_path: []const u8, allocator: std.mem.Allocator) !void {
    ma.init(allocator);
    defer ma.deinit(.{});

    var m = try tflite.modelFromData(model_data);
    defer m.deinit();

    var o = try tflite.interpreterOptions();
    defer o.deinit();

    var i = try tflite.interpreter(m, o);
    defer i.deinit();

    try i.allocateTensors();

    var inputTensor = i.inputTensor(0);
    var outputTensor = i.outputTensor(0);

    var input = inputTensor.data(f32);
    var output = outputTensor.data(f32);

    var buffer: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(buffer[0..]);
    const shape = try inputTensor.shape(fba.allocator());
    const img_size = std.math.sqrt(@intCast(u32, shape.items[1]));
    shape.deinit();

    var x: c_int = undefined;
    var y: c_int = undefined;
    var n: c_int = undefined;
    var img_data = stb.stbi_loadf(
        @ptrCast([*]const u8, img_path),
        &x,
        &y,
        &n,
        stb.STBI_grey,
    );
    defer stb.stbi_image_free(img_data);
    if (img_data == null) {
        std.log.err("image file {s} not found", .{img_path});
        std.os.exit(1);
    }

    const resize_result = stb.stbir_resize_float(img_data, x, y, 0, @ptrCast([*]f32, input), img_size, img_size, 0, n);
    if (resize_result != 1) {
        std.log.err("resize img failed", .{});
        std.os.exit(1);
    }

    try i.invoke();
    var writer = std.io.getStdOut().writer();
    var result = std.sort.argMax(f32, output, {}, comptime std.sort.asc(f32)) orelse unreachable;
    try writer.print("result:\t{}\n", .{result});

    std.debug.print("score\n", .{});
    for (output) |op, index| std.debug.print("{}\t{d:.3}\n", .{ index, op });
}

test "test" {
    try mainI("./mnist_png/testing/3/2008.png", std.testing.allocator);
}
