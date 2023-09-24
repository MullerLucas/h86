const std = @import("std");

const instr = @import("../instr.zig");
const InstrOp = instr.InstrOp;

// ----------------------------------------------

pub const InstrDecoder = struct {
    buff: [1024]u8,
    count: usize,
    idx: usize = 0,

    pub const DecodeError = error {
        InvalidOpcode,
        UnsupportedMod,
    };

    pub fn init(path: []const u8) !InstrDecoder {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var self = InstrDecoder {
            .buff  = undefined,
            .count = 0,
        };
        self.count = try file.readAll(&self.buff);

        return self;
    }

    pub fn next(self: *InstrDecoder) ?InstrOp {
        const byte = self.next_byte();
        defer _ = self.next_byte();
        return InstrDecoder.decode_op_type(byte);
    }

    // ------------------------------------------

    inline fn next_byte(self: *InstrDecoder) u8 {
        defer self.idx += 1;
        return self.buff[self.idx];
    }

    fn decode_op_type(byte: u8) ?InstrOp {
        const union_info: std.builtin.Type.Union = blk: {
            const type_info = @typeInfo(InstrOp);
            break :blk switch (type_info) {
                .Union => |ti| ti,
                else => @compileError("not an union"),
            };
        };

        inline for (union_info.fields) |field| {
            const sub_res = InstrDecoder.decode_op_sub_type(field.type, byte);
            if (sub_res) |sub| {
                return @unionInit(InstrOp, field.name, sub);
            }
        }

        return null;
    }

    fn decode_op_sub_type(comptime T: type, byte: u8) ?T {
        for (T.infos, 0..) |inf, i| {
            const shift: u3 = @intCast(8 - inf.bits);
            const op = byte >> shift;
            if (op == inf.opcode) {
                return @enumFromInt(i);
            }
        }
        return null;
    }
};
