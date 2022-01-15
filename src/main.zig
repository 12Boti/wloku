const w4 = @import("wasm4.zig");

const Sprite = struct {
    w: u8,
    h: u8,
    data: []const u8,

    fn load(comptime name: []const u8) Sprite {
        const data = @embedFile("../build/assets/" ++ name);
        // TODO: values could be packed into u3 if smaller cart is needed
        return comptime Sprite{
            .w = data[0],
            .h = data[1],
            .data = data[2..],
        };
    }

    fn draw(s: Sprite, x: i32, y: i32) void {
        drawRotated(s, x, y, 0);
    }

    fn drawRotated(s: Sprite, x: i32, y: i32, rot: u2) void {
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
                if (px < 0 or px >= w4.CANVAS_SIZE or py < 0 or py >= w4.CANVAS_SIZE)
                    continue;
                const idx = @intCast(usize, x + px + (y + py) * w4.CANVAS_SIZE);
                w4.FRAMEBUFFER.set(idx, @intCast(u2, pix - 1));
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
var playerrot: u2 = 0;

export fn update() void {
    w4.DRAW_COLORS.* = 2;
    w4.text("Hello from Zig!", 10, 10);

    const pad = w4.GAMEPAD1;
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
    if (playervy < 0) {
        playerrot = 0;
    } else if (playervx < 0) {
        playerrot = 1;
    } else if (playervy > 0) {
        playerrot = 2;
    } else if (playervx > 0) {
        playerrot = 3;
    }
    var newx = playerx + playervx;
    var newy = playery + playervy;
    if (!isColliding(newx + 1, newy + 1, 5, 5)) {
        playerx = newx;
        playery = newy;
    }

    tank.drawRotated(
        @floatToInt(i32, playerx),
        @floatToInt(i32, playery),
        playerrot,
    );
}

fn isColliding(x: f32, y: f32, w: f32, h: f32) bool {
    if (x < 0 or x + w > w4.CANVAS_SIZE or y < 0 or y + h > w4.CANVAS_SIZE) {
        return true;
    }
    return false;
}
