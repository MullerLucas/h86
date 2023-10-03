const std = @import("std");

const corez = @import("corez");

const instr        = @import("instr.zig");
const InstrMovOp   = instr.InstrMov;
const InstrDecoder = instr.InstrDecoder;

const listing_0037 = "./resources/asm/listing_0037_single_register_mov";
const listing_0038 = "./resources/asm/listing_0038_many_register_mov";
const listing_0039 = "./resources/asm/listing_0039_more_movs";
const listing_0040 = "./resources/asm/listing_0040_challenge_movs";

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var decoder = try InstrDecoder.init(listing_0038);

    var buf: [1024]u8 = undefined;
    var cur = corez.mem.StrCursor.from_slice(buf[0..]);

    try stdout.print("bits 16\n\n", .{});
    while (try decoder.next()) |i| {
        try i.to_asm_str(&cur);
        try stdout.print("{s}\n", .{cur.to_slice()});
        cur.reset();
    }
    try bw.flush();
}
