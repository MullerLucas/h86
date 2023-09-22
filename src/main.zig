const std = @import("std");
const InstrDecoder = @import("instr_decoder.zig").InstrDecoder;

const listing_0037 = "./resources/asm/listing_0037_single_register_mov";
const listing_0038 = "./resources/asm/listing_0038_many_register_mov";

pub fn main() !void {
    try InstrDecoder.decode_file(listing_0038, 16);
}
