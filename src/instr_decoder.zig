const std = @import("std");

// ----------------------------------------------

const DecodeError = error {
    InvalidOpcode,
    UnsupportedMod,
};

// ----------------------------------------------

const opcode_move = 0b1000_1000;

pub const Opcode = enum(u8) {
    mov = opcode_move,

    pub fn try_from_u8(value: u8) !Opcode {
        switch (value) {
            opcode_move => return .mov,
            else => return DecodeError.InvalidOpcode,
        }
    }

    pub inline fn mnemonic(self: Opcode) []const u8 {
        return @tagName(self);
    }
};


fn decode_register(reg: u3, w: u1) []const u8 {
    if (w == 0) {
        switch (reg) {
            0b000 => return "al",
            0b001 => return "cl",
            0b010 => return "dl",
            0b011 => return "bl",
            0b100 => return "ah",
            0b101 => return "ch",
            0b110 => return "dh",
            0b111 => return "bh",
        }
    } else {
        switch (reg) {
            0b000 => return "ax",
            0b001 => return "cx",
            0b010 => return "dx",
            0b011 => return "bx",
            0b100 => return "sp",
            0b101 => return "bp",
            0b110 => return "si",
            0b111 => return "di",
        }
    }
}

const mask_op  = 0b1111_1100;
const mask_d   = 0b0000_0010;
const mask_w   = 0b0000_0001;
const mask_mod = 0b1100_0000;
const mask_reg = 0b0011_1000;
const mask_rm  = 0b0000_0111;

const shift_op : u3 = 2;
const shift_d  : u3 = 1;
const shift_w  : u3 = 0;
const shift_mod: u3 = 6;
const shift_reg: u3 = 3;
const shift_rm : u3 = 0;


pub const InstrDecoder = struct {

    pub fn decode_file(path: []const u8, num_bits: u8) !void {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var buff: [1024]u8 = undefined;
        const count = try file.readAll(&buff);

        try stdout.print("bits {d}\n\n", .{num_bits});

        var i: usize = 0;
        while (i < count) {
            const byte_1 = buff[i];
            const byte_2 = buff[i + 1];

            const mod: u2 = @intCast((byte_2 & mask_mod) >> 6);
            if (mod != 0b11) {
                return DecodeError.UnsupportedMod;
            }

            const op_raw = byte_1 & 0xFC;
            const op     = try Opcode.try_from_u8(op_raw);

            const d: u1 = @intCast((byte_1 & mask_d) >> 2);
            const w: u1 = @intCast(byte_1 & mask_w);

            const reg = (byte_2 & mask_reg) >> 3;
            const reg_mnemonic = decode_register(@intCast(reg), w);

            const rm = (byte_2 & mask_rm);
            const rm_mnemonic = decode_register(@intCast(rm), w);

            var dst_mnemonic: []const u8 = undefined;
            var src_mnemonic: []const u8 = undefined;

            if (d == 0) {
                dst_mnemonic = rm_mnemonic;
                src_mnemonic = reg_mnemonic;
            } else {
                dst_mnemonic = reg_mnemonic;
                src_mnemonic = rm_mnemonic;
            }

            try stdout.print("{s} {s}, {s}\n", .{
                op.mnemonic(),
                dst_mnemonic,
                src_mnemonic,
            });
            i += 2;
        }

        try bw.flush(); // don't forget to flush!

    }
};
