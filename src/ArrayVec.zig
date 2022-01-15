pub const ArrayVecError = error{CapacityError};

pub fn ArrayVec(comptime T: type, comptime CAPACITY: usize) type {
    return struct {
        buf: [CAPACITY]T = undefined,
        size: usize = 0,

        const Self = @This();

        pub fn append(self: *Self, item: T) ArrayVecError!void {
            if (self.size >= CAPACITY)
                return error.CapacityError;
            self.buf[self.size] = item;
            self.size += 1;
        }

        pub fn swapRemove(self: *Self, i: usize) T {
            if (self.size - 1 == i) return self.pop();

            const old_item = self.buf[i];
            self.buf[i] = self.pop();
            return old_item;
        }

        pub fn pop(self: *Self) T {
            const val = self.buf[self.size - 1];
            self.size -= 1;
            return val;
        }
    };
}
