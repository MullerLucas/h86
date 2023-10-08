const std = @import("std");
const assert = std.debug.assert;

pub const StrCursor = Cursor(u8);

pub fn Cursor(comptime T: type) type {
    return struct {
        ptr:      [*]T,
        capacity: usize,
        offset:   usize,

        pub const Self = @This();

        pub fn from_slice(items: []T) Self {
            return Self {
                .ptr      = items.ptr,
                .capacity = items.len,
                .offset   = 0,
            };
        }

        pub fn to_slice(self: *Self) []T {
            return (self.ptr - self.offset)[0..self.offset];
        }

        pub fn reset(self: *Self) void {
            self.ptr    -= self.offset;
            self.offset = 0;
        }

        pub fn try_push(self: *Self, slice: []const T) !void {
            if ((self.offset + slice.len) > self.capacity) {
                return error.OutOfMemory;
            }

            @memcpy(self.ptr, slice);
            self.offset += slice.len;
            self.ptr  += slice.len;
        }

        // pub fn push(self: *Self, slice: []const T) void {
        //     assert((self.offset + slice.len) <= self.capacity);
        //
        //     @memcpy(self.ptr, slice);
        //     self.offset += slice.len;
        //     self.ptr  += slice.len;
        // }
    };
}
