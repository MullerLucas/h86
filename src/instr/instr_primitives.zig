const std   = @import("std");
const instr = @import("../instr.zig");

const corez     = @import("corez");
const StrCursor = corez.mem.StrCursor;


pub const Encoding = struct {
    value: u8,
    mask:  u8,
    bits:  u8,

    pub fn init(comptime T: type, comptime opcode: u8) Encoding {
        const type_info = @typeInfo(T);

        const int_info: std.builtin.Type.Int = switch(type_info) {
            .Int => |ti| ti,
            else => @compileError("not an int"),
        };

        if (int_info.signedness == .signed) {
            @compileError("signed int");
        }

        if (int_info.bits > 8) {
            @compileError("int too big");
        }

        const bits: u8 = @intCast(int_info.bits);

        var mask: u8 = 0;
        inline for (0..bits) |i| {
            mask |= 1 << i;
        }

        return Encoding {
            .value = opcode,
            .bits  = bits,
            .mask  = mask,
        };
    }
};

// ----------------------------------------------


pub const Opcode = union(enum){
    mov: instr.OpcodeMov,

    pub const infos: [1][]Encoding = .{
        instr.OpcodeMov.info_slice(),
    };

    pub inline fn to_asm_str(self: Opcode) []const u8 {
        return @tagName(self);
    }

    pub fn decode(byte: u8) ?Opcode {
        const union_info: std.builtin.Type.Union = blk: {
            const type_info = @typeInfo(Opcode);
            break :blk switch (type_info) {
                .Union => |ti| ti,
                else => @compileError("not an union"),
            };
        };

        inline for (union_info.fields) |field| {
            const sub_res = try Opcode.decode_sub(field.type, byte);
            if (sub_res) |sub| {
                return @unionInit(Opcode, field.name, sub);
            }
        }

        return null;
    }

    fn decode_sub(comptime T: type, byte: u8) !?T {
        for (T.encodings, 0..) |enc, i| {
            const shift: u3 = @intCast(8 - enc.bits);
            const op = byte >> shift;
            if (op == enc.value) {
                return @enumFromInt(i);
            }
        }
        return null;
    }

};

// ----------------------------------------------

pub const MemMode = enum (u2) {
    memory_mode_no_displacement,
    memory_mode_8_bit_displacement,
    memory_mode_16_bit_displacement,
    register_mode_no_displacement,

    pub const encodings = [_]Encoding {
        Encoding.init(u2, 0b00),
        Encoding.init(u2, 0b01),
        Encoding.init(u2, 0b10),
        Encoding.init(u2, 0b11),
    };
};

// ----------------------------------------------

pub const Direction = enum (u1) {
    reg_is_source,
    reg_is_dest,

    pub const encodings = [_]Encoding {
        Encoding.init(u1, 0b0),
        Encoding.init(u1, 0b1),
    };
};

// ----------------------------------------------

pub const Width = enum (u1) {
    byte_data,
    word_data,

    pub const encodings = [_]Encoding {
        Encoding.init(u1, 0b0),
        Encoding.init(u1, 0b1),
    };
};

// ----------------------------------------------

pub const Register = union(enum) {
    byte: ByteRegister,
    word: WordRegister,

    pub fn to_asm_str(self: Register) []const u8 {
        return switch(self) {
            .byte => |b| b.to_asm_str(),
            .word => |w| w.to_asm_str(),
        };
    }

    pub fn decode(byte: u8, offset: u3, w: Width) !Register {
        return switch (w) {
            .byte_data => Register { .byte = instr.InstrDecoder.decode_instr_enum(ByteRegister, byte, offset) orelse return instr.DecodeError.InvalidEncoding },
            .word_data => Register { .word = instr.InstrDecoder.decode_instr_enum(WordRegister, byte, offset) orelse return instr.DecodeError.InvalidEncoding },
        };
    }
};

pub const ByteRegister = enum (u3) {
    al = 0b000,
    cl = 0b001,
    dl = 0b010,
    bl = 0b011,
    ah = 0b100,
    ch = 0b101,
    dh = 0b110,
    bh = 0b111,

    pub const encodings = [_]Encoding {
        Encoding.init(u3, 0b000),
        Encoding.init(u3, 0b001),
        Encoding.init(u3, 0b010),
        Encoding.init(u3, 0b011),
        Encoding.init(u3, 0b100),
        Encoding.init(u3, 0b101),
        Encoding.init(u3, 0b110),
        Encoding.init(u3, 0b111),
    };

    pub inline fn to_asm_str(self: ByteRegister) []const u8 {
        return @tagName(self);
    }
};

pub const WordRegister = enum (u3) {
    ax = 0b000,
    cx = 0b001,
    dx = 0b010,
    bx = 0b011,
    sp = 0b100,
    bp = 0b101,
    si = 0b110,
    di = 0b111,

    pub const encodings = [_]Encoding {
        Encoding.init(u3, 0b000),
        Encoding.init(u3, 0b001),
        Encoding.init(u3, 0b010),
        Encoding.init(u3, 0b011),
        Encoding.init(u3, 0b100),
        Encoding.init(u3, 0b101),
        Encoding.init(u3, 0b110),
        Encoding.init(u3, 0b111),
    };

    pub inline fn to_asm_str(self: WordRegister) []const u8 {
        return @tagName(self);
    }
};

// ----------------------------------------------

pub const EffectiveAddressCalc = union(enum) {

};

// ----------------------------------------------

pub const RegisterMemory = union(enum) {
    reg: Register,
    mem: EffectiveAddressCalc,
};

// ----------------------------------------------

pub const Displacement = union(enum) {
    byte: u8,
    word: u16,
};

// ----------------------------------------------

pub const Instr = union(enum) {
    mov: instr.InstrMov,

    pub fn decode(iter: *instr.ByteIter) !?Instr {
        const b1     = iter.peek()             orelse return null;
        const opcode = instr.Opcode.decode(b1) orelse return null;

        return switch (opcode) {
            Opcode.mov => Instr { .mov = try instr.InstrMov.decode(iter) },
            // else       => instr.DecodeError.InvalidEncoding,
        };
    }

    pub fn to_asm_str(self: *const Instr, cur: *StrCursor) !void {
        switch (self.*) {
            inline else  => |i| return i.to_asm_str(cur),
        }
    }
};

// ----------------------------------------------
