const w4 = @import("wasm4.zig");

const Sprite = struct {
    w: u8,
    h: u8,
    data: []const u8,

    fn load(comptime name: []const u8) Sprite {
        const data = @embedFile("../build/assets/" ++ name);
        return comptime Sprite{
            .w = data[0],
            .h = data[1],
            .data = data[2..],
        };
    }

    fn draw(s: Sprite, x: u32, y: u32) void {
        drawRotated(s, x, y, 0);
    }

    fn drawRotated(s: Sprite, x: u32, y: u32, rot: u2) void {
        var dy: u32 = 0;
        while (dy < s.h) : (dy += 1) {
            var dx: u32 = 0;
            while (dx < s.w) : (dx += 1) {
                const pix = s.data[dx + dy * s.w];
                if (pix == 0) continue;
                var px: u32 = undefined;
                var py: u32 = undefined;
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
                const idx = x + px + (y + py) * w4.CANVAS_SIZE;
                const off = @intCast(u3, idx % 4) * 2;
                w4.FRAMEBUFFER[idx / 4] &= ~(@intCast(u8, 3) << off);
                w4.FRAMEBUFFER[idx / 4] |= (pix - 1) << off;
            }
        }
    }
};

const Gamepad = struct {
    v: u32,

    fn left(self: Gamepad) bool {
        return self.v & w4.BUTTON_LEFT != 0;
    }
    fn right(self: Gamepad) bool {
        return self.v & w4.BUTTON_RIGHT != 0;
    }
    fn up(self: Gamepad) bool {
        return self.v & w4.BUTTON_UP != 0;
    }
    fn down(self: Gamepad) bool {
        return self.v & w4.BUTTON_DOWN != 0;
    }

    fn pad1() Gamepad {
        return .{ .v = w4.GAMEPAD1.* };
    }
    fn pad2() Gamepad {
        return .{ .v = w4.GAMEPAD2.* };
    }
    fn pad3() Gamepad {
        return .{ .v = w4.GAMEPAD3.* };
    }
    fn pad4() Gamepad {
        return .{ .v = w4.GAMEPAD4.* };
    }
};

const tank = Sprite.load("tank");
const tankspeed = 0.5;
var playerx: f32 = 10;
var playery: f32 = 70;
var playervx: f32 = 0;
var playervy: f32 = 0;
var playerrot: u2 = 0;

export fn update() void {
    w4.DRAW_COLORS.* = 2;
    w4.text("Hello from Zig!", 10, 10);

    const pad = Gamepad.pad1();
    if (playervy == 0) {
        playervx = 0;
        if (pad.left()) {
            playervx -= tankspeed;
        }
        if (pad.right()) {
            playervx += tankspeed;
        }
    }
    if (playervx == 0) {
        playervy = 0;
        if (pad.up()) {
            playervy -= tankspeed;
        }
        if (pad.down()) {
            playervy += tankspeed;
        }
    }
    playerx += playervx;
    playery += playervy;
    if (playervy < 0) {
        playerrot = 0;
    } else if (playervx < 0) {
        playerrot = 1;
    } else if (playervy > 0) {
        playerrot = 2;
    } else if (playervx > 0) {
        playerrot = 3;
    }

    tank.drawRotated(
        @floatToInt(u32, playerx),
        @floatToInt(u32, playery),
        playerrot,
    );
}
