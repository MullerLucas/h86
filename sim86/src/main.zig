const std = @import("std");
const InstrDecoder = @import("instr_decoder.zig").InstrDecoder;

const listing_0037 = "../part_1/listing_0037_single_register_mov";
const listing_0038 = "../part_1/listing_0038_many_register_mov";

pub fn main() !void {
    try InstrDecoder.decode_file(listing_0038, 16);
}
