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
        var dy: u32 = 0;
        while (dy < s.h) : (dy += 1) {
            var dx: u32 = 0;
            while (dx < s.w) : (dx += 1) {
                const pix = s.data[dx + dy * s.w];
                if (pix == 0) continue;
                const idx = x + dx + (y + dy) * w4.CANVAS_SIZE;
                const off = @intCast(u3, idx % 4) * 2;
                w4.FRAMEBUFFER[idx / 4] &= ~(@intCast(u8, 3) << off);
                w4.FRAMEBUFFER[idx / 4] |= (pix - 1) << off;
            }
        }
    }
};

const tank = Sprite.load("tank");
const tankspeed = 0.5;
var playerx: f32 = 10;
var playery: f32 = 70;
var playervx: f32 = 0;
var playervy: f32 = 0;

export fn update() void {
    w4.DRAW_COLORS.* = 2;
    w4.text("Hello from Zig!", 10, 10);

    const gamepad = w4.GAMEPAD1.*;
    if (playervy == 0) {
        playervx = 0;
        if (gamepad & w4.BUTTON_LEFT != 0) {
            playervx -= tankspeed;
        }
        if (gamepad & w4.BUTTON_RIGHT != 0) {
            playervx += tankspeed;
        }
    }
    if (playervx == 0) {
        playervy = 0;
        if (gamepad & w4.BUTTON_UP != 0) {
            playervy -= tankspeed;
        }
        if (gamepad & w4.BUTTON_DOWN != 0) {
            playervy += tankspeed;
        }
    }
    playerx += playervx;
    playery += playervy;

    tank.draw(@floatToInt(u32, playerx), @floatToInt(u32, playery));
}
