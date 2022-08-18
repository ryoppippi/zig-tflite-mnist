const std = @import("std");
const tflite = @import("zig-tflite");
const c = @import("c.zig");

const img_size = 28;

const model_data = @embedFile("../notebook/model.tflite");

pub fn main() !void {
    var args = try std.process.argsWithAllocator(std.heap.page_allocator);
    defer args.deinit();
    const prog = args.next();
    const img_path: [:0]const u8 = args.next() orelse {
        std.log.err("usage: {s} [filename]", .{prog.?});
        std.os.exit(1);
    };

    var x: c_int = undefined;
    var y: c_int = undefined;
    var n: c_int = undefined;
    var img_data = c.stbi_loadf(img_path, &x, &y, &n, c.STBI_grey);
    defer c.stbi_image_free(img_data);
    if (img_data == null) {
        std.log.err("image file {s} not found", .{img_path});
        std.os.exit(1);
    }

    const resized_size = img_size * img_size;
    var resized_img: [resized_size]f32 = undefined;
    const resize_result = c.stbir_resize_float(img_data, x, y, 0, @ptrCast([*]f32, &resized_img), img_size, img_size, 0, n);
    if (resize_result != 1) {
        std.log.err("resize img failed", .{});
        std.os.exit(1);
    }

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

    for (input) |*t, index| t.* = resized_img[index];
    try i.invoke();
    var writer = std.io.getStdOut().writer();
    var result = std.sort.argMax(f32, output, {}, comptime std.sort.asc(f32)) orelse unreachable;
    try writer.print("result:\t{}\n", .{result});

    std.debug.print("score\n", .{});
    for (output) |op, index| std.debug.print("{}\t{d:.3}\n", .{ index, op });
}
