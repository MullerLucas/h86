const std = @import("std");

const instr        = @import("../instr.zig");
const Instr        = instr.Instr;
const InstrMov     = instr.InstrMov;
const Opcode       = instr.Opcode;
const OpcodeMov    = instr.OpcodeMov;
const Direction    = instr.Direction;
const Width        = instr.Width;
const MemMode      = instr.MemMode;
const Register     = instr.Register;
const ByteRegister = instr.ByteRegister;
const WordRegister = instr.WordRegister;

// ----------------------------------------------

pub const DecodeError = error {
    InvalidOpcode,
    UnsupportedMod,
    InvalidEncoding,
    NotImplemented,
};

// ----------------------------------------------

pub const ByteIter = struct {
    slice: []const u8,

    pub inline fn is_empty(self: *const ByteIter) bool {
        return self.slice.len == 0;
    }

    pub inline fn peek(self: *const ByteIter) ?u8 {
        if (self.slice.len == 0) { return null; }
        return self.slice[0];
    }

    pub inline fn peek_unchecked(self: *const ByteIter) u8 {
        return self.slice[0];
    }

    pub inline fn next(self: *ByteIter) ?u8 {
        if (self.slice.len == 0) { return null; }
        defer self.slice = self.slice[1..];
        return self.slice[0];
    }

    pub inline fn try_next(self: *ByteIter) !u8 {
        return self.next() orelse return DecodeError.InvalidEncoding;
    }
};

// ----------------------------------------------

pub const InstrDecoder = struct {
    buff:  [1024]u8,
    count: usize,
    idx:   usize = 0,
    iter:  ByteIter,


    pub fn init(path: []const u8) !InstrDecoder {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var self = InstrDecoder {
            .buff  = undefined,
            .count = 0,
            .iter  = undefined,
        };
        self.count = try file.readAll(&self.buff);
        self.iter  = ByteIter { .slice =  self.buff[0..self.count] };

        return self;
    }

    pub fn next(self: *InstrDecoder) !?Instr {
        std.debug.print("next: 0b{b}\n", .{self.iter.peek_unchecked()});
        if (self.iter.peek() == null) { return null; }

        // return try instr.Instr.decode(&self.iter);
        return instr.Instr.decode(&self.iter) catch null;
    }

    pub fn decode_instr_enum(comptime T: type, byte: u8, offset: u3) !T {
        const type_info = @typeInfo(T);
        if (type_info != .Enum) {
            @compileError("not an enum");
        }

        for (T.encodings, 0..) |enc, i| {
            const shift: u3 = @intCast(8 - enc.bits - offset);
            const value = (byte >> shift) & enc.mask;
            if (value == enc.value) {
                return @enumFromInt(i);
            }
        }

        return instr.DecodeError.InvalidEncoding;
    }

};
