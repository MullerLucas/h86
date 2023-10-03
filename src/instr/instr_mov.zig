const std = @import("std");
const instr = @import("../instr.zig");

const corez = @import("corez");
const StrCursor = corez.mem.StrCursor;

// ----------------------------------------------

pub const OpcodeMov = enum {
    register_or_memory_to_or_from_register,
    immediate_to_register_or_memory,
    immediate_to_register,
    memory_to_accumulator,
    accumulator_to_memory,
    register_or_memeory_to_segment_register,
    segment_register_to_register_or_memory,

    pub const encodings = [_]instr.Encoding {
        instr.Encoding.init(u6, 0b1000_10),
        instr.Encoding.init(u7, 0b1100_011),
        instr.Encoding.init(u4, 0b1011),
        instr.Encoding.init(u7, 0b1010_000),
        instr.Encoding.init(u7, 0b1010_001),
        instr.Encoding.init(u8, 0b1000_1110),
        instr.Encoding.init(u8, 0b1000_1100),
    };
};

// ----------------------------------------------

pub const InstrMov = union(enum) {
    register_or_memory_to_or_from_register: struct {
        d:    instr.Direction,
        w:    instr.Width,
        mod:  instr.MemMode,
        reg:  instr.Register,
        rm:   instr.Register,
        disp: ?instr.Displacement,
    },
    immediate_to_register_or_memory,
    immediate_to_register,
    memory_to_accumulator,
    accumulator_to_memory,
    register_or_memeory_to_segment_register,
    segment_register_to_register_or_memory,

    pub fn to_asm_str(self: *const InstrMov, cur: *StrCursor) !void {
        cur.push("mov ");

        switch (self.*) {
            .register_or_memory_to_or_from_register => |i| {
                switch (i.mod) {
                    // .memory_mode_no_displacement,
                    // .memory_mode_8_bit_displacement,
                    // .memory_mode_16_bit_displacement,
                    .register_mode_no_displacement => {
                        switch (i.d) {
                            .reg_is_source => {
                                cur.push(i.reg.to_asm_str());
                                cur.push(" ");
                                cur.push(i.rm.to_asm_str());
                            },
                            .reg_is_dest   => {
                                cur.push(i.reg.to_asm_str());
                                cur.push(" ");
                                cur.push(i.rm.to_asm_str());
                            },
                        }
                    },
                    else => cur.push("todo"),
                }
            },
            else => {
                try cur.try_push("todo");
            }
        }
    }

    pub fn decode(iter: *instr.ByteIter) !InstrMov {
        return InstrMov.decode_register_or_memory_to_or_from_register(iter);
    }

    fn decode_register_or_memory_to_or_from_register(iter: *instr.ByteIter) !InstrMov {
        const b1 = try iter.try_next();
        const b2 = try iter.try_next();

        const d   = instr.InstrDecoder.decode_instr_enum(instr.Direction, b1, 1) orelse return instr.DecodeError.InvalidEncoding;
        const w   = instr.InstrDecoder.decode_instr_enum(instr.Width, b1, 0)     orelse return instr.DecodeError.InvalidEncoding;
        const mod = instr.InstrDecoder.decode_instr_enum(instr.MemMode, b2, 6) orelse return instr.DecodeError.InvalidEncoding;

        const reg = try instr.Register.decode(b2, 0, w);
        const rm  = try instr.Register.decode(b2, 3, w);

        return InstrMov { .register_or_memory_to_or_from_register = .{
            .d = d,
            .w = w,
            .mod = mod,
            .reg = reg,
            .rm  = rm,
            .disp = null,
        } };
    }
};
