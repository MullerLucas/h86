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

    pub fn decode(byte: u8) !Opcode {
        const union_info: std.builtin.Type.Union = blk: {
            const type_info = @typeInfo(Opcode);
            break :blk switch (type_info) {
                .Union => |ti| ti,
                else => @compileError("not an union"),
            };
        };

        inline for (union_info.fields) |field| {
            const sub = try Opcode.decode_sub(field.type, byte);
            return @unionInit(Opcode, field.name, sub);
        }

        return instr.DecodeError.InvalidEncoding;
    }

    fn decode_sub(comptime T: type, byte: u8) !T {
        for (T.encodings, 0..) |enc, i| {
            const shift: u3 = @intCast(8 - enc.bits);
            const op = byte >> shift;
            if (op == enc.value) {
                return @enumFromInt(i);
            }
        }
        return instr.DecodeError.InvalidEncoding;
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
    byte,
    word,

    pub const encodings = [_]Encoding {
        Encoding.init(u1, 0b0),
        Encoding.init(u1, 0b1),
    };

    pub fn is_byte(self: Width) bool {
        return switch (self) {
            .byte => true,
            .word => false,
        };
    }
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
            .byte => Register { .byte = try instr.InstrDecoder.decode_instr_enum(ByteRegister, byte, offset) },
            .word => Register { .word = try instr.InstrDecoder.decode_instr_enum(WordRegister, byte, offset) },
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

pub const EffectiveAddressCalc = enum {
    bx_plus_si,
    bx_plus_di,
    bp_plus_si,
    bp_plus_di,
    si,
    di,
    bp_or_direct_address,
    bx,

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

    const asm_strs = [_][]const u8 {
        "bx + si",
        "bx + di",
        "bp + si",
        "bp + di",
        "si",
        "di",
        "bp",
        "bx",
    };

    pub fn to_asm_str(self: EffectiveAddressCalc, buf: []u8, mod: MemMode, val: ?Scalar) ![]const u8 {
        return switch (mod) {
            .register_mode_no_displacement => return instr.DecodeError.InvalidEncoding,
            .memory_mode_no_displacement   => switch (self) {
                .bp_or_direct_address => blk: {
                    const v = val orelse return instr.DecodeError.InvalidEncoding;
                    break :blk try std.fmt.bufPrint(buf, "[{d}]", .{v.to_u16()});
                },
                else => try std.fmt.bufPrint(buf, "[{s}]", .{EffectiveAddressCalc.asm_strs[@intFromEnum(self)]}),
            },
            else => blk: {
                const v = val orelse return instr.DecodeError.InvalidEncoding;
                break :blk try std.fmt.bufPrint(buf, "[{s} + {d}]", .{EffectiveAddressCalc.asm_strs[@intFromEnum(self)], v.to_u16()});
            },
        };
    }

    pub fn decode(byte: u8, offset: u3) !EffectiveAddressCalc {
        return instr.InstrDecoder.decode_instr_enum(EffectiveAddressCalc, byte, offset);
    }
};

// ----------------------------------------------

pub const RegisterMemory = union(enum) {
    reg: Register,
    mem: EffectiveAddressCalc,

    pub fn decode(byte: u8, offset: u3, mod: MemMode, w: Width) !RegisterMemory {
        return switch (mod) {
            .memory_mode_no_displacement,
            .memory_mode_8_bit_displacement,
            .memory_mode_16_bit_displacement => RegisterMemory { .mem = try EffectiveAddressCalc.decode(byte, offset) },
            .register_mode_no_displacement   => RegisterMemory { .reg = try Register.decode(byte, offset, w) },
        };
    }

    pub fn to_asm_str(self: RegisterMemory, buf: []u8, mod: MemMode, val: ?Scalar) ![]const u8 {
        return switch (self) {
            .reg => |r| r.to_asm_str(),
            .mem => |m| m.to_asm_str(buf, mod, val),
        };
    }

    pub fn is_effectife_address_calc(self: RegisterMemory, val: EffectiveAddressCalc) bool {
        return switch (self) {
            .reg => false,
            .mem => |m| m == val,
        };
    }
};

// ----------------------------------------------

pub const Scalar = union(enum) {
    byte: u8,
    word: u16,

    pub fn decode(iter: *instr.ByteIter, is_byte: bool) !Scalar {
        if (is_byte) {
            const b1 = try iter.try_next();
            return Scalar { .byte = @intCast(b1) };
        } else {
            const b1 = try iter.try_next();
            const b2 = try iter.try_next();
            const val: u16 = @as(u16, b1) | @as(u16, b2) << 8;
            return Scalar { .word = val };
        }
    }

    pub fn to_asm_str(self: *const Scalar, buf: []u8) ![]const u8 {
        return switch (self.*) {
            inline else  => |i| try std.fmt.bufPrint(buf, "{d}", .{i}),
        };
    }

    pub fn to_u16(self: *const Scalar) u16 {
        return switch (self.*) {
            inline else  => |i| @intCast(i),
        };
    }
};

// ----------------------------------------------

pub const Instr = union(enum) {
    mov: instr.InstrMov,

    pub fn decode(iter: *instr.ByteIter) !Instr {
        const b1     = iter.peek() orelse return instr.DecodeError.InvalidEncoding;
        const opcode = try instr.Opcode.decode(b1);

        return switch (opcode) {
            Opcode.mov => Instr { .mov = try instr.InstrMov.decode(iter) },
        };
    }

    pub fn to_asm_str(self: *const Instr, cur: *StrCursor) !void {
        switch (self.*) {
            inline else  => |i| return i.to_asm_str(cur),
        }
    }
};

// ----------------------------------------------
