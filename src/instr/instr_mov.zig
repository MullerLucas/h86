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
        rm:   instr.RegisterMemory,
        disp: ?instr.Scalar,
    },
    immediate_to_register_or_memory,
    immediate_to_register : struct {
        w:    instr.Width,
        reg:  instr.Register,
        data: instr.Scalar,
    },
    memory_to_accumulator,
    accumulator_to_memory,
    register_or_memeory_to_segment_register,
    segment_register_to_register_or_memory,

    pub fn to_asm_str(self: *const InstrMov, cur: *StrCursor) !void {
        var buf: [100]u8 = undefined;

        switch (self.*) {
            .register_or_memory_to_or_from_register => |i| {
                cur.push("; register_or_memory_to_or_from_register\n");

                switch (i.mod) {
                    .memory_mode_no_displacement => {
                        cur.push("; memory_mode_no_displacement\n");
                        cur.push("mov ");
                        cur.push(i.reg.to_asm_str());
                        cur.push(", ");
                        cur.push(try i.rm.to_asm_str(&buf, i.mod, i.disp));
                    },
                    .memory_mode_8_bit_displacement => {
                        std.debug.print("TEST: {any}", .{i});
                        cur.push("; memory_mode_8_bit_displacement\n");
                        cur.push("mov ");
                        cur.push(i.reg.to_asm_str());
                        cur.push(", ");
                        cur.push(try i.rm.to_asm_str(&buf, i.mod, i.disp));
                    },
                    .memory_mode_16_bit_displacement => {
                        cur.push("; memory_mode_16_bit_displacement\n");
                        cur.push("mov ");
                        cur.push(i.reg.to_asm_str());
                        cur.push(", ");
                        cur.push(try i.rm.to_asm_str(&buf, i.mod, i.disp));
                    },
                    .register_mode_no_displacement => {
                        cur.push("; register_mode_no_displacement\n");
                        cur.push("mov ");

                        switch (i.d) {
                            .reg_is_source => {
                                cur.push(i.reg.to_asm_str());
                                cur.push(", ");
                                cur.push(try i.rm.to_asm_str(&buf, i.mod, i.disp));
                            },
                            .reg_is_dest   => {
                                cur.push(i.reg.to_asm_str());
                                cur.push(", ");
                                cur.push(try i.rm.to_asm_str(&buf, i.mod, i.disp));
                            },
                        }
                    },
                }
            },
            .immediate_to_register_or_memory => {
                cur.push("; immediate_to_register_or_memory\n");
                cur.push("todo");
            },
            .immediate_to_register => |i| {
                cur.push("; immediate_to_register\n");
                cur.push("mov ");
                cur.push(i.reg.to_asm_str());
                cur.push(", ");
                cur.push(try i.data.to_asm_str(buf[0..]));
            },
            .memory_to_accumulator => {
                cur.push("; memory_to_accumulator\n");
                cur.push("todo");
            },
            .accumulator_to_memory => {
                cur.push("; accumulator_to_memory\n");
                cur.push("todo");
            },
            .register_or_memeory_to_segment_register => {
                cur.push("; register_or_memeory_to_segment_register\n");
                cur.push("todo");
            },
            .segment_register_to_register_or_memory => {
                cur.push("; segment_register_to_register_or_memory\n");
                cur.push("todo");
            },
        }
    }

    pub fn decode(iter: *instr.ByteIter) !InstrMov {
        const opcode = try instr.InstrDecoder.decode_instr_enum(OpcodeMov, iter.peek_unchecked(), 0);

        return switch (opcode) {
            .register_or_memory_to_or_from_register => InstrMov.decode_register_or_memory_to_or_from_register(iter),
            .immediate_to_register_or_memory,
            .immediate_to_register                  => InstrMov.decode_immediate_to_registe(iter),
            .memory_to_accumulator,
            .accumulator_to_memory,
            .register_or_memeory_to_segment_register,
            .segment_register_to_register_or_memory => {
                unreachable;
            }
        };
    }

    fn decode_register_or_memory_to_or_from_register(iter: *instr.ByteIter) !InstrMov {
        const b1 = try iter.try_next();
        const b2 = try iter.try_next();

        const d   = try instr.InstrDecoder.decode_instr_enum(instr.Direction, b1, 6);
        const w   = try instr.InstrDecoder.decode_instr_enum(instr.Width,     b1, 7);
        const mod = try instr.InstrDecoder.decode_instr_enum(instr.MemMode,   b2, 0);

        const reg  = try instr.Register.decode(b2, 2, w);
        const rm   = try instr.RegisterMemory.decode(b2, 5, mod, w);
        const disp = switch (mod) {
            .memory_mode_no_displacement     => null,
            .memory_mode_8_bit_displacement  => try instr.Scalar.decode(iter, true),
            .memory_mode_16_bit_displacement => try instr.Scalar.decode(iter, false),
            .register_mode_no_displacement   => blk: {
                if (rm.is_effectife_address_calc(.bp_or_direct_address)) {
                    break :blk try instr.Scalar.decode(iter, w.is_byte());
                } else {
                    break :blk null;
                }
            }
        };

        return InstrMov { .register_or_memory_to_or_from_register = .{
            .d = d,
            .w = w,
            .mod = mod,
            .reg = reg,
            .rm  = rm,
            .disp = disp,
        } };
    }

    fn decode_immediate_to_registe(iter: *instr.ByteIter) !InstrMov {
        const b1 = try iter.try_next();

        const w    = try instr.InstrDecoder.decode_instr_enum(instr.Width, b1, 4);
        const reg  = try instr.Register.decode(b1, 5, w);
        const data = try instr.Scalar.decode(iter, w.is_byte());

        return InstrMov { .immediate_to_register = .{
            .w    = w,
            .reg  = reg,
            .data = data,
        }};
    }
};
