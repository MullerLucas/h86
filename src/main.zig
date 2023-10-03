const std = @import("std");

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

    try stdout.print("bits 16\n\n", .{});
    while (try decoder.next()) |i| {
        // try stdout.print("{any}\n", .{op});
        try stdout.print("{s}\n", .{i.to_asm_string()});
    }
    try bw.flush();
}
