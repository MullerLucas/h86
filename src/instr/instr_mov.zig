const instr = @import("../instr.zig");

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

    pub fn to_asm_string(self: *const InstrMov) []const u8 {
        _ = self;
        return "mov";
    }

    pub fn decode(iter: *instr.ByteIter) !InstrMov {
        return InstrMov.decode_register_or_memory_to_or_from_register(iter);
    }

    fn decode_register_or_memory_to_or_from_register(iter: *instr.ByteIter) !InstrMov {
        const b1 = try iter.try_next();
        const b2 = try iter.try_next();

        const d = instr.InstrDecoder.decode_instr_enum(instr.Direction, b1, 1) orelse return instr.DecodeError.InvalidEncoding;
        const w = instr.InstrDecoder.decode_instr_enum(instr.Width, b1, 0)     orelse return instr.DecodeError.InvalidEncoding;

        const mod = instr.InstrDecoder.decode_instr_enum(instr.MemMode, b2, 6) orelse return instr.DecodeError.InvalidEncoding;

        // const reg_offsets = switch(d) {
        //     .reg_is_source => .{ @as(u3, 0), @as(u3, 3) },
        //     .reg_is_dest   => .{ @as(u3, 3), @as(u3, 0) },
        // };
        // const dest_reg   = try InstrDecoder.decode_reg(b2, reg_offsets[0], w);
        // _ = dest_reg;
        // const source_reg = try InstrDecoder.decode_reg(b2, reg_offsets[1], w);
        // _ = source_reg;

        const reg = try instr.Register.decode(b2, 0, w);
        const rm  = try instr.Register.decode(b2, 3, w);
        // std.debug.print("mov {s}, {s}\n", .{dest_reg.to_asm_str(), source_reg.to_asm_str()});

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
