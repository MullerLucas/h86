pub const std    = @import("std");

pub const corez  = @import("corez");
pub const Logger = corez.log.Scoped(.h86);

const memory  = @import("memory.zig");
const decoder = @import("decoder.zig");
const instr   = @import("instr.zig");


pub const Emulator = struct {
    pub fn disassemble(alloc: std.mem.Allocator, path: []const u8) !void {
        Logger.info("disassemble file '{s}'\n", .{path});

        var mem = blk: {
            const Memory = memory.Memory(1024 * 1024);
            var mem = try alloc.create(Memory);
            mem.* = try Memory.from_file(path);
            break :blk mem;
        };
        defer alloc.destroy(mem);

        const iter = mem.iter();
        _ = iter;

        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        try stdout.print("bits 16\n\n", .{});
        try bw.flush();
    }
};
