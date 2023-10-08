const std = @import("std");

pub fn Memory(comptime capacity: usize) type {
    return struct {
        data: [capacity]u8,
        len:  usize,

        const Self = @This();

        pub fn from_file(path: []const u8) !Self {
            var mem: Self = undefined;

            const file = try std.fs.cwd().openFile(path, .{});
            defer file.close();

            mem.len = try file.readAll(&mem.data);
            return mem;
        }

        pub fn iter(self: *Self) MemoryIter(capacity) {
            return MemoryIter(capacity) {
                .mem = self,
                .idx = 0,
            };
        }
    };
}

pub fn MemoryIter(comptime capacity: usize) type {
    return struct {
        mem: *Memory(capacity),
        idx: usize,

        const Self = @This();

        pub fn next_at(self: *Self, offset: usize) ?u8 {
            if (self.idx + offset >= capacity) {
                return null;
            }
            defer self.idx += offset;
            return self.mem.data[self.idx + offset];
        }

        pub inline fn next(self: *Self) ?u8 {
            return self.next_at(1);
        }
    };
}
