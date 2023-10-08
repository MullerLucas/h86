const std   = @import("std");
const corez = @import("corez");
const h86   = @import("h86.zig");

const listing_0037 = "./resources/asm/listing_0037_single_register_mov";
const listing_0038 = "./resources/asm/listing_0038_many_register_mov";
const listing_0039 = "./resources/asm/listing_0039_more_movs";
const listing_0040 = "./resources/asm/listing_0040_challenge_movs";

// TODO(lm):
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) {
            h86.Logger.err("memory was leaked", .{});
        }
    }

    try h86.Emulator.disassemble(gpa.allocator(), listing_0037);
}
