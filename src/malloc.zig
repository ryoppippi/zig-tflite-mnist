// original code from zig-gamedev https://github.com/michal-z/zig-gamedev/blob/befbf1adb4/libs/zstbi/src/zstbi.zig

const std = @import("std");
const assert = std.debug.assert;

var mem_allocator: ?std.mem.Allocator = null;
var mem_allocations: ?std.AutoHashMap(usize, usize) = null;
var mem_mutex: std.Thread.Mutex = .{};
const mem_alignment = 16;

pub fn init(allocator: std.mem.Allocator) void {
    assert(mem_allocator == null);
    mem_allocator = allocator;
    mem_allocations = std.AutoHashMap(usize, usize).init(allocator);
}

const Config = struct {
    check_allocation_count: bool = false,
};

pub fn deinit(config: Config) void {
    assert(mem_allocator != null);
    std.debug.assert(mem_allocations != null);
    if (config.check_allocation_count) std.debug.assert(mem_allocations.?.count() == 0);
    mem_allocations.?.deinit();
    mem_allocations = null;
    mem_allocator = null;
}

export fn malloc(size: usize) callconv(.C) ?*anyopaque {
    mem_mutex.lock();
    defer mem_mutex.unlock();
    std.debug.print("malloc({})\n", .{size});

    const mem = mem_allocator.?.allocBytes(
        mem_alignment,
        size,
        0,
        @returnAddress(),
    ) catch @panic("zstbi: out of memory");

    mem_allocations.?.put(@ptrToInt(mem.ptr), size) catch @panic("zstbi: out of memory");

    return mem.ptr;
}

export fn realloc(ptr: ?*anyopaque, size: usize) callconv(.C) ?*anyopaque {
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const old_size = if (ptr != null) mem_allocations.?.get(@ptrToInt(ptr.?)).? else 0;
    const old_mem = if (old_size > 0)
        @ptrCast([*]u8, ptr)[0..old_size]
    else
        @as([*]u8, undefined)[0..0];

    const new_mem = mem_allocator.?.reallocBytes(
        old_mem,
        mem_alignment,
        size,
        mem_alignment,
        0,
        @returnAddress(),
    ) catch @panic("zstbi: out of memory");

    if (ptr != null) {
        const removed = mem_allocations.?.remove(@ptrToInt(ptr.?));
        std.debug.assert(removed);
    }

    mem_allocations.?.put(@ptrToInt(new_mem.ptr), size) catch @panic("zstbi: out of memory");

    return new_mem.ptr;
}

export fn free(maybe_ptr: ?*anyopaque) callconv(.C) void {
    if (maybe_ptr) |ptr| {
        mem_mutex.lock();
        defer mem_mutex.unlock();

        const size = mem_allocations.?.fetchRemove(@ptrToInt(ptr)).?.value;
        const mem = @ptrCast(
            [*]align(mem_alignment) u8,
            @alignCast(mem_alignment, ptr),
        )[0..size];
        mem_allocator.?.free(mem);
    }
}
