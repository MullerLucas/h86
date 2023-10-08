const std   = @import("std");
const corez = @import("corez");
const h86   = @import("h86.zig");
const instr = h86.instr;

// ----------------------------------------------

pub const EncBitUsage = enum {
    literal,
    mod,
    reg,
    rm,

    d,
    w,

    pub fn bits(self: EncBitUsage, data: anytype) EncBits {
        return switch (self) {
            .literal => blk: {
                if (@TypeOf(data[0]) != comptime_int) { @compileError("not an comptime_int"); }

                break :blk EncBits {
                    .usage = .literal,
                    .count = corez.math.count_bits(data[0]),
                    .shift = 0,
                    .value = 0,
                };
            },
            .mod => EncBits {
                .usage = .mod,
                .count = 2,
                .shift = 0,
                .value = 0,
            },
            .reg => EncBits {
                .usage = .reg,
                .count = 3,
                .shift = 0,
                .value = 0,
            },
            .rm => EncBits {
                .usage = .rm,
                .count = 3,
                .shift = 0,
                .value = 0,
            },
            .d => EncBits {
                .usage = .d,
                .count = 1,
                .shift = 0,
                .value = 0,
            },
            .w => EncBits {
                .usage = .w,
                .count = 1,
                .shift = 0,
                .value = 0,
            },
        };
    }
};

pub const EncBits = struct {
    usage: EncBitUsage,
    count: u8,
    shift: u8,
    value: u8,
};

pub const EncFormat = struct {
    op:   instr.OperationType,
    bits: [16]EncBits,

    fn from_literal(op: instr.OperationType, raw_bits: anytype) EncFormat {
        var bits: [16]EncBits = undefined;

        for (raw_bits, 0..) |rb, i| {
            bits[i] = rb;
        }

        return EncFormat {
            .op   = op,
            .bits = raw_bits,
        };
    }
};

// ----------------------------------------------


const EBU = EncBitUsage;

pub const encodings = [_]EncFormat {
    // Register/memory to/from register
    EncFormat.from_literal(.mov, .{
        EBU.literal.bits(.{0b100010}),
        EBU.d.bits(.{}),
        EBU.w.bits(.{}),
        EBU.mod.bits(.{}),
        EBU.reg.bits(.{}),
        EBU.rm.bits(.{}),
    }),
};
