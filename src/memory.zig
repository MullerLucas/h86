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

        pub fn iter(self: *Self) ByteIter {
            return ByteIter {
                .data = self.data[0..self.len],
                .idx = 0,
                .idx_speculative = 0,
            };
        }
    };
}

pub const ByteIter = struct {
    data: []u8,
    idx: usize,
    idx_speculative: usize,

    const Self = @This();

    pub fn next(self: *Self) ?u8 {
        if (self.idx >= self.data.len) {
            return null;
        }
        defer {
            self.idx += 1;
            self.idx_speculative = self.idx;
        }
        return self.data[self.idx];
    }

    pub fn next_speculative(self: *Self) ?u8 {
        if (self.idx_speculative >= self.data.len) {
            return null;
        }
        defer self.idx_speculative += 1;

        return self.data[self.idx_speculative];
    }

    pub fn apply_speculative(self: *Self) void {
        self.idx = self.idx_speculative;
    }

    pub fn reset_speculative(self: *Self) void {
        self.idx_speculative = self.idx;
    }
};
