//! https://edge.edx.org/c4x/BITSPilani/EEE231/asset/8086_family_Users_Manual_1_.pdf - page 162

const std = @import("std");

// ----------------------------------------------

pub const InstrType = union(enum){
    mov: MovInstrSubType,
};

// ----------------------------------------------

pub const MovInstrSubType = enum {
    register_or_memory_to_or_from_register,
    immediate_to_register_or_memory,
    immediate_to_register,
    memory_to_accumulator,
    accumulator_to_memory,
    register_or_memeory_to_segment_register,
    segment_register_to_register_or_memory,
};

// ----------------------------------------------

pub const InstrBuffer = struct {
    stream: std.ArrayList(InstrType),
};
