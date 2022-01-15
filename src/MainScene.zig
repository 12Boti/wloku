const Self = @This();
const std = @import("std");
const w4 = @import("wasm4.zig");
const Sprite = @import("Sprite.zig");
const ArrayVec = @import("ArrayVec.zig").ArrayVec;

const wallsSize = 100;
const wallColor = 3;
const Walls = std.PackedIntArray(u1, wallsSize * wallsSize);
const bulletSpeed = 0.8;
const bulletColor = 1;
const shootDelay = 60;

player1: Tank = Tank{
    .x = 10,
    .y = 70,
    .vx = 0,
    .vy = 0,
    .speed = 0.5,
    .rot = 0,
    .shootTimer = 0,
    .sprite = &Sprite.load("tank"),
},
// use `std.mem.zeroes` here because it makes compilation much faster than
// looping and setting all elements to 0
walls: Walls = std.mem.zeroes(Walls),
bullets: ArrayVec(Bullet, 128) = .{},
// TODO: gather entropy from player input
rng: std.rand.DefaultPrng = std.rand.DefaultPrng.init(0xdeadbeef),

pub fn init() Self {
    var s = Self{};
    s.generateWalls();
    return s;
}

pub fn update(s: *Self) void {
    s.updateBullets();
    s.updatePlayer(&s.player1, w4.GAMEPAD1.*);
}

pub fn draw(s: Self) void {
    w4.DRAW_COLORS.* = 2;
    w4.text("Hello from Zig!", 10, 10);
    s.drawWalls();
    s.drawBullets();
    s.player1.draw();
}

fn generateWalls(s: *Self) void {
    var x: usize = 0;
    while (x < wallsSize) : (x += 1) {
        var y: usize = 0;
        while (y < wallsSize) : (y += 1) {
            if (s.rng.random().float(f32) < 0.5) {
                s.walls.set(x + y * wallsSize, 1);
            }
        }
    }
}

fn drawWalls(s: Self) void {
    var x: usize = 0;
    while (x < wallsSize) : (x += 1) {
        var y: usize = 0;
        while (y < wallsSize) : (y += 1) {
            if (s.walls.get(x + y * wallsSize) == 1) {
                w4.setPixel(x + 30, y + 30, wallColor);
            }
        }
    }
}

fn explodeWalls(s: *Self, x: u32, y: u32) void {
    const radius = 15;
    var dy: u32 = 0;
    while (dy < radius) : (dy += 1) {
        var dx: u32 = 0;
        while (dx < radius) : (dx += 1) {
            const xx = x + dx - radius / 2;
            const yy = y + dy - radius / 2;
            if (xx < 30 or yy < 30) continue;
            const idx = xx - 30 + (yy - 30) * wallsSize;
            if (idx >= s.walls.len) continue;
            const distSq = (x - xx) * (x - xx) + (y - yy) * (y - yy);
            if (s.rng.random().float(f32) > @intToFloat(f32, distSq) / radius / radius * 3) {
                s.walls.set(idx, 0);
            }
        }
    }
}

fn updateBullets(s: *Self) void {
    var i: usize = 0;
    while (i < s.bullets.size) {
        const b = &s.bullets.buf[i];
        b.x += b.vx;
        b.y += b.vy;
        if (isOutOfBounds(b.x, b.y, 1, 1)) {
            _ = s.bullets.swapRemove(i);
            continue;
        }
        if (s.isCollidingWithWalls(
            @floatToInt(u32, b.x),
            @floatToInt(u32, b.y),
            1,
            1,
        )) {
            s.explodeWalls(
                @floatToInt(u32, b.x),
                @floatToInt(u32, b.y),
            );
            _ = s.bullets.swapRemove(i);
            continue;
        }
        i += 1;
    }
}

fn drawBullets(s: Self) void {
    var i: usize = 0;
    while (i < s.bullets.size) : (i += 1) {
        const b = s.bullets.buf[i];
        if (b.x < 0 or b.x >= w4.CANVAS_SIZE or b.y < 0 or b.y >= w4.CANVAS_SIZE)
            continue;
        w4.setPixel(@floatToInt(u32, b.x), @floatToInt(u32, b.y), bulletColor);
    }
}

fn updatePlayer(s: *Self, tank: *Tank, pad: w4.Gamepad) void {
    // movement
    if (tank.vy == 0) {
        tank.vx = 0;
        if (pad.left()) {
            tank.vx -= tank.speed;
        }
        if (pad.right()) {
            tank.vx += tank.speed;
        }
    }
    if (tank.vx == 0) {
        tank.vy = 0;
        if (pad.up()) {
            tank.vy -= tank.speed;
        }
        if (pad.down()) {
            tank.vy += tank.speed;
        }
    }
    var newx = tank.x + tank.vx;
    var newy = tank.y + tank.vy;
    if (!s.isColliding(newx + 1, newy + 1, 5, 5)) {
        tank.x = newx;
        tank.y = newy;
    }
    // rotation
    if (tank.vy < 0) {
        tank.rot = 0;
    } else if (tank.vx < 0) {
        tank.rot = 1;
    } else if (tank.vy > 0) {
        tank.rot = 2;
    } else if (tank.vx > 0) {
        tank.rot = 3;
    }
    // shooting
    tank.shootTimer -|= 1;
    if (tank.shootTimer == 0 and pad.b1()) {
        tank.shootTimer = shootDelay;
        var bullet = Bullet{
            .x = tank.x + 3,
            .y = tank.y + 3,
            .vx = 0,
            .vy = 0,
        };
        switch (tank.rot) {
            0 => {
                bullet.y -= 3;
                bullet.vy = -bulletSpeed;
            },
            1 => {
                bullet.x -= 3;
                bullet.vx = -bulletSpeed;
            },
            2 => {
                bullet.y += 3;
                bullet.vy = bulletSpeed;
            },
            3 => {
                bullet.x += 3;
                bullet.vx = bulletSpeed;
            },
        }
        s.bullets.append(bullet) catch {
            w4.trace("warning: too many bullets");
        };
    }
}

fn isColliding(s: Self, x: f32, y: f32, w: u32, h: u32) bool {
    if (isOutOfBounds(x, y, w, h)) {
        return true;
    }
    if (s.isCollidingWithWalls(
        @floatToInt(u32, x),
        @floatToInt(u32, y),
        w,
        h,
    )) {
        return true;
    }
    return false;
}

fn isOutOfBounds(x: f32, y: f32, w: u32, h: u32) bool {
    return x < 0 or
        x + @intToFloat(f32, w) > w4.CANVAS_SIZE or
        y < 0 or
        y + @intToFloat(f32, h) > w4.CANVAS_SIZE;
}

fn isCollidingWithWalls(s: Self, x: u32, y: u32, w: u32, h: u32) bool {
    var dy: u32 = 0;
    while (dy < h) : (dy += 1) {
        var dx: u32 = 0;
        while (dx < w) : (dx += 1) {
            const xx = x + dx;
            const yy = y + dy;
            if (xx < 30 or yy < 30) continue;
            const idx = xx - 30 + (yy - 30) * wallsSize;
            if (idx >= s.walls.len) continue;
            if (s.walls.get(idx) == 1) return true;
        }
    }
    return false;
}

const Bullet = struct {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
};

const Tank = struct {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
    speed: f32,
    rot: u2,
    shootTimer: u32,
    sprite: *const Sprite,

    fn draw(self: Tank) void {
        self.sprite.drawRotated(
            @floatToInt(i32, self.x),
            @floatToInt(i32, self.y),
            self.rot,
        );
    }
};
