const std = @import("std");

const corez = @import("corez");

const h86       = @import("h86.zig");
const ByteIter  = h86.memory.ByteIter;

const instr       = h86.instr;
const Instruction = instr.Instruction;

const encoding = h86.encoding;
const EncRule  = encoding.EncRule;

pub const Decoder = struct {

    pub fn decode(iter: *ByteIter) !void {
        for (&encoding.rules) |*rule| {
            if (Decoder.try_decode(iter, rule)) |_| {
                return;
            }
        }

        return h86.H86Error.InvalidEncoding;
    }

    fn try_decode(iter: *ByteIter, rule: *const EncRule) ?void {
        var bits: [corez.math.count_enum_fields(encoding.EncBitUsage)]u32 = undefined;
        var has_bits: u32 = 0;

        var bits_pending_count: u8 = 0;
        var bits_pending: u8 = 0;

        for (rule.as_slice()) |test_bits| {
            var read_bits = test_bits.value;
            if (test_bits.count != 0) {
                if (bits_pending_count == 0) {
                    bits_pending_count = 8;
                    bits_pending = iter.next_speculative() orelse return null;
                }

                // encoded segments won't cross byte boundaries
                std.debug.assert(test_bits.count <= bits_pending_count);

                bits_pending_count -= test_bits.count;
                read_bits = bits_pending;
                read_bits >>= @intCast(bits_pending_count);
                read_bits &= ~(@as(u8, 0xff) << @as(u3, @intCast(test_bits.count)));
            }

            if (test_bits.usage == .literal) {
                if (test_bits.value != read_bits) {
                    return null;
                }
            } else {
                bits[@intFromEnum(test_bits.usage)] |= (read_bits << @intCast(test_bits.shift));
                has_bits |= (@as(u8, 1) << @intFromEnum(test_bits.usage));
            }
        }

        iter.apply_speculative();
        std.debug.print("TEST success\n", .{});
    }
};
