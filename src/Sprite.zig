const Self = @This();
const w4 = @import("wasm4.zig");

w: u8,
h: u8,
data: []const u8,

pub fn load(comptime name: []const u8) Self {
    const data = @embedFile("../build/assets/" ++ name);
    // TODO: values could be packed into u3 if smaller cart is needed
    return comptime Self{
        .w = data[0],
        .h = data[1],
        .data = data[2..],
    };
}

pub fn draw(s: Self, x: i32, y: i32) void {
    drawRotated(s, x, y, 0);
}

pub fn drawRotated(s: Self, x: i32, y: i32, rot: u2) void {
    var dy: u31 = 0;
    while (dy < s.h) : (dy += 1) {
        var dx: u31 = 0;
        while (dx < s.w) : (dx += 1) {
            const pix = s.data[dx + dy * s.w];
            if (pix == 0) continue;
            var px: i32 = undefined;
            var py: i32 = undefined;
            switch (rot) {
                0 => {
                    px = dx;
                    py = dy;
                },
                1 => {
                    px = dy;
                    py = s.w - dx - 1;
                },
                2 => {
                    px = s.w - dx - 1;
                    py = s.h - dy - 1;
                },
                3 => {
                    px = s.h - dy - 1;
                    py = dx;
                },
            }
            const xx = x + px;
            const yy = y + py;
            if (xx < 0 or xx >= w4.CANVAS_SIZE or yy < 0 or yy >= w4.CANVAS_SIZE)
                continue;
            w4.setPixel(@intCast(u32, xx), @intCast(u32, yy), @intCast(u2, pix - 1));
        }
    }
}
