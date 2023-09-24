//! https://edge.edx.org/c4x/BITSPilani/EEE231/asset/8086_family_Users_Manual_1_.pdf - page 162

pub usingnamespace @import("instr/instr_decoder.zig");

const std = @import("std");

const corez      = @import("corez");
const StackArray = corez.collections.StackArray;

// ----------------------------------------------

pub const OpInfo = struct {
    opcode: u8,
    mask:   u8,
    bits:   u8,

    pub fn init(comptime T: type, comptime opcode: u8) OpInfo {
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

        return OpInfo {
            .opcode = opcode,
            .bits   = bits,
            .mask   = mask,
        };
    }
};

// ----------------------------------------------


pub const InstrOp = union(enum){
    mov: InstrMovOp,

    pub const infos: [1][]OpInfo = .{
        InstrMovOp.info_slice(),
    };

    pub inline fn mnemonic(self: InstrOp) []const u8 {
        return @tagName(self);
    }
};

// ----------------------------------------------

pub const InstrMovOp = enum(u8) {
    register_or_memory_to_or_from_register,
    immediate_to_register_or_memory,
    immediate_to_register,
    memory_to_accumulator,
    accumulator_to_memory,
    register_or_memeory_to_segment_register,
    segment_register_to_register_or_memory,

    pub const op_count = 7;
    pub const infos: [op_count]OpInfo = .{
        OpInfo.init(u6, 0b1000_10),
        OpInfo.init(u7, 0b1100_011),
        OpInfo.init(u4, 0b1011),
        OpInfo.init(u7, 0b1010_000),
        OpInfo.init(u7, 0b1010_001),
        OpInfo.init(u8, 0b1000_1110),
        OpInfo.init(u8, 0b1000_1100),
    };
};

// ----------------------------------------------

pub const InstrMod = enum (u2) {
    memory_mode_no_displacement     = 0b00,
    memory_mode_8_bit_displacement  = 0b01,
    memory_mode_16_bit_displacement = 0b10,
    register_mode_no_displacement   = 0b11,
};

// ----------------------------------------------

pub const InstrD = enum (u1) {
    reg_is_source = 0b0,
    reg_is_dest   = 0b1,
};

// ----------------------------------------------

pub const InstrW = enum (u1) {
    byte_data = 0b0,
    word_data = 0b1,
};

// ----------------------------------------------

pub const InstrReg = union(enum) {
    byte: InstrByteReg,
    word: InstrWordReg,
};

pub const InstrByteReg = enum (u3) {
    al = 0b000,
    cl = 0b001,
    dl = 0b010,
    bl = 0b011,
    ah = 0b100,
    ch = 0b101,
    dh = 0b110,
    bh = 0b111,
};

pub const InstrWordReg = enum (u3) {
    ax = 0b000,
    cx = 0b001,
    dx = 0b010,
    bx = 0b011,
    sp = 0b100,
    bp = 0b101,
    si = 0b110,
    di = 0b111,
};

// ----------------------------------------------
