const std = @import("std");

const instr        = @import("../instr.zig");
const InstrOp      = instr.InstrOp;
const InstrMoveOp  = instr.InstrMovOp;
const InstrD       = instr.InstrD;
const InstrW       = instr.InstrW;
const InstrMod     = instr.InstrMod;
const InstrReg     = instr.InstrReg;
const InstrByteReg = instr.InstrByteReg;
const InstrWordReg = instr.InstrWordReg;

// ----------------------------------------------

pub const DecodeError = error {
    InvalidOpcode,
    UnsupportedMod,
    InvalidEncoding,
};

// ----------------------------------------------

pub const InstrIter = struct {
    slice: []const u8,

    inline fn is_empty(self: *const InstrIter) bool {
        return self.slice.len == 0;
    }

    inline fn peek(self: *const InstrIter) ?u8 {
        if (self.slice.len == 0) { return null; }
        return self.slice[0];
    }

    inline fn peek_unchecked(self: *const InstrIter) u8 {
        return self.slice[0];
    }

    inline fn next(self: *InstrIter) ?u8 {
        if (self.slice.len == 0) { return null; }
        defer self.slice = self.slice[1..];
        return self.slice[0];
    }

    inline fn try_next(self: *InstrIter) !u8 {
        return self.next() orelse return DecodeError.InvalidEncoding;
    }
};

// ----------------------------------------------

pub const InstrDecoder = struct {
    buff:  [1024]u8,
    count: usize,
    idx:   usize = 0,
    iter:  InstrIter,


    pub fn init(path: []const u8) !InstrDecoder {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var self = InstrDecoder {
            .buff  = undefined,
            .count = 0,
            .iter  = undefined,
        };
        self.count = try file.readAll(&self.buff);
        self.iter  = InstrIter { .slice =  self.buff[0..self.count] };

        return self;
    }

    pub fn next(self: *InstrDecoder) !?InstrOp {
        return InstrDecoder.decode_op_type(&self.iter);
    }

    fn decode_op_type(iter: *InstrIter) !?InstrOp {
        if (iter.is_empty()) { return null; }

        const union_info: std.builtin.Type.Union = blk: {
            const type_info = @typeInfo(InstrOp);
            break :blk switch (type_info) {
                .Union => |ti| ti,
                else => @compileError("not an union"),
            };
        };

        inline for (union_info.fields) |field| {
            const sub_res = try InstrDecoder.decode_op_sub_type(field.type, iter);
            if (sub_res) |sub| {
                return @unionInit(InstrOp, field.name, sub);
            }
        }

        return null;
    }

    fn decode_op_sub_type(comptime T: type, iter: *InstrIter) !?T {
        for (T.encodings, 0..) |enc, i| {
            const shift: u3 = @intCast(8 - enc.bits);
            const op = iter.peek_unchecked() >> shift;
            if (op == enc.value) {
                try InstrDecoder.decode_op_move(iter);
                return @enumFromInt(i);
            }
        }
        return null;
    }

    fn decode_instr_enum(comptime T: type, byte: u8, offset: u3) ?T {
        const type_info = @typeInfo(T);
        if (type_info != .Enum) {
            @compileError("not an enum");
        }

        for (T.encodings, 0..) |enc, i| {
            const value = (byte >> offset) & enc.mask;
            if (value == enc.value) {
                return @enumFromInt(i);
            }
        }
        return null;
    }

    fn decode_reg(byte: u8, offset: u3, w: InstrW) !InstrReg {
        return switch (w) {
            .byte_data => InstrReg { .byte = InstrDecoder.decode_instr_enum(InstrByteReg, byte, offset) orelse return DecodeError.InvalidEncoding },
            .word_data => InstrReg { .word = InstrDecoder.decode_instr_enum(InstrWordReg, byte, offset) orelse return DecodeError.InvalidEncoding },
        };
    }

    fn decode_op_move(iter: *InstrIter) !void {
        const b1 = try iter.try_next();
        const b2 = try iter.try_next();

        const d = InstrDecoder.decode_instr_enum(InstrD, b1, 1) orelse return DecodeError.InvalidEncoding;
        const w = InstrDecoder.decode_instr_enum(InstrW, b1, 0) orelse return DecodeError.InvalidEncoding;

        const mod = InstrDecoder.decode_instr_enum(InstrMod, b2, 6);
        _ = mod;

        const reg_offsets = switch(d) {
            .reg_is_source => .{ @as(u3, 0), @as(u3, 3) },
            .reg_is_dest   => .{ @as(u3, 3), @as(u3, 0) },
        };
        const dest_reg   = try InstrDecoder.decode_reg(b2, reg_offsets[0], w);
        const source_reg = try InstrDecoder.decode_reg(b2, reg_offsets[1], w);

        std.debug.print("mov {s}, {s}\n", .{dest_reg.to_asm_str(), source_reg.to_asm_str()});
    }

    fn decode_op_move_register_or_memory_to_or_from_register() InstrMoveOp {

    }
};
