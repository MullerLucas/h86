//! https://edge.edx.org/c4x/BITSPilani/EEE231/asset/8086_family_Users_Manual_1_.pdf - page 162

const std = @import("std");

const corez      = @import("corez");
const StackArray = corez.collections.StackArray;

// ----------------------------------------------

pub const InstrBuffer = struct {
    stream: StackArray(InstrOp, 512),
};

// ----------------------------------------------

pub const InstrOp = union(enum){
    mov: InstrMovOp,

    pub inline fn mnemonic(self: InstrOp) []const u8 {
        return @tagName(self);
    }
};

// ----------------------------------------------

pub const InstrMovOp = enum(u8) {
    register_or_memory_to_or_from_register  = 0b1000_10,
    immediate_to_register_or_memory         = 0b1100_011,
    immediate_to_register                   = 0b1011,
    memory_to_accumulator                   = 0b1010_000,
    accumulator_to_memory                   = 0b1010_001,
    register_or_memeory_to_segment_register = 0b1000_1110,
    segment_register_to_register_or_memory  = 0b1000_1100,
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
