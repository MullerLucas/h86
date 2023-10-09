pub const std    = @import("std");

pub const corez  = @import("corez");
pub const Logger = corez.log.Scoped(.h86);

pub const memory   = @import("memory.zig");
pub const decoder  = @import("decoder.zig");
pub const instr    = @import("instr.zig");
pub const encoding = @import("encoding.zig");

pub const mem_usage  = 1024 * 1024;
pub const MemoryEmu  = memory.Memory(mem_usage);

pub const H86Error = error {
    InvalidEncoding,
    InvalidData,
};

pub const Emulator = struct {
    pub fn disassemble(alloc: std.mem.Allocator, path: []const u8) !void {
        Logger.info("disassemble file '{s}'\n", .{path});

        for (encoding.rules) |enc| {
            Logger.debug("{}\n\n", .{enc});
        }

        var mem = blk: {
            var mem = try alloc.create(MemoryEmu);
            mem.* = try MemoryEmu.from_file(path);
            break :blk mem;
        };
        defer alloc.destroy(mem);
        var iter = mem.iter();

        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        try stdout.print("bits 16\n\n", .{});
        try bw.flush();

        try decoder.Decoder.decode(&iter);
    }
};
