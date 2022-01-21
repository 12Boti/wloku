const Self = @This();
const std = @import("std");
const w4 = @import("wasm4.zig");
const Sprite = @import("Sprite.zig");
const Noise = @import("Noise.zig");
const rng = @import("rng.zig").rng;
const distSq = @import("math.zig").distSq;

const wallColor = 3;
const Walls = std.PackedIntArray(u1, w4.CANVAS_SIZE * w4.CANVAS_SIZE);
const bulletSpeed = 0.8;
const bulletColor = 1;
const shootDelay = 60;

player1: Tank = Tank{
    .x = 150,
    .y = 70,
    .sprite = &Sprite.load("tank"),
},
player2: Tank = Tank{
    .x = 10,
    .y = 70,
    .sprite = &Sprite.load("tank"),
},
// use `std.mem.zeroes` here because it makes compilation much faster than
// looping and setting all elements to 0
walls: Walls = std.mem.zeroes(Walls),
bullets: std.BoundedArray(Bullet, 128) = .{},

pub fn init() Self {
    var s = Self{};
    s.generateWalls();
    return s;
}

pub fn update(s: *Self) void {
    s.updateBullets();
    s.updatePlayer(&s.player1, w4.GAMEPAD1.*);
    s.updatePlayer(&s.player2, w4.GAMEPAD2.*);
}

pub fn draw(s: Self) void {
    w4.DRAW_COLORS.* = 2;
    w4.text("Hello from Zig!", 10, 10);
    s.drawWalls();
    s.drawBullets();
    s.player1.draw();
    s.player2.draw();
}

fn generateWalls(s: *Self) void {
    var noise = Noise.init(rng.int(u64));
    const freq = 0.15;
    var x: usize = 0;
    while (x < w4.CANVAS_SIZE) : (x += 1) {
        var y: usize = 0;
        while (y < w4.CANVAS_SIZE) : (y += 1) {
            const fx = @intToFloat(f32, x);
            const fy = @intToFloat(f32, y);
            var v = noise.get(fx * freq, fy * freq);
            const ds = std.math.min(
                distSq(f32, fx, fy, s.player1.centerx(), s.player1.centery()),
                distSq(f32, fx, fy, s.player2.centerx(), s.player2.centery()),
            );
            if (ds < 500) {
                v += 1 / ds * 50;
            }
            if (v < 0.4) {
                s.walls.set(x + y * w4.CANVAS_SIZE, 1);
            }
        }
    }
}

fn drawWalls(s: Self) void {
    var x: usize = 0;
    while (x < w4.CANVAS_SIZE) : (x += 1) {
        var y: usize = 0;
        while (y < w4.CANVAS_SIZE) : (y += 1) {
            if (s.walls.get(x + y * w4.CANVAS_SIZE) == 1) {
                w4.setPixel(x, y, wallColor);
            }
        }
    }
}

fn explodeWalls(s: *Self, x: i32, y: i32) void {
    const radius = 20;
    var dy: i32 = 0;
    while (dy < radius) : (dy += 1) {
        var dx: i32 = 0;
        while (dx < radius) : (dx += 1) {
            const xx = x + dx - radius / 2;
            const yy = y + dy - radius / 2;
            if (xx < 0 or
                xx >= w4.CANVAS_SIZE or
                yy < 0 or
                yy >= w4.CANVAS_SIZE) continue;
            const idx = @intCast(usize, xx + yy * w4.CANVAS_SIZE);
            const ds = distSq(i32, x, y, xx, yy);
            const v = @intToFloat(f32, ds) / radius / radius * 6 - 0.2;
            if (rng.float(f32) > v) {
                s.walls.set(idx, 0);
            }
        }
    }
}

fn updateBullets(s: *Self) void {
    var i: usize = 0;
    while (i < s.bullets.len) {
        const b = &s.bullets.slice()[i];
        b.x += b.vx;
        b.y += b.vy;
        if (isOutOfBounds(b.x, b.y, 1, 1)) {
            _ = s.bullets.swapRemove(i);
            continue;
        }
        if (s.isCollidingWithWalls(
            floorToInt(i32, b.x),
            floorToInt(i32, b.y),
            1,
            1,
        )) {
            s.explodeWalls(
                floorToInt(i32, b.x),
                floorToInt(i32, b.y),
            );
            _ = s.bullets.swapRemove(i);
            continue;
        }
        i += 1;
    }
}

fn drawBullets(s: Self) void {
    var i: usize = 0;
    while (i < s.bullets.len) : (i += 1) {
        const b = s.bullets.get(i);
        if (b.x < 0 or b.x >= w4.CANVAS_SIZE or b.y < 0 or b.y >= w4.CANVAS_SIZE)
            continue;
        w4.setPixel(floorToInt(u32, b.x), floorToInt(u32, b.y), bulletColor);
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
    if (!s.isColliding(newx + 2, newy + 2, 3, 3)) {
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
            .x = @floor(tank.x) + 3,
            .y = @floor(tank.y) + 3,
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
        floorToInt(i32, x),
        floorToInt(i32, y),
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

fn isCollidingWithWalls(s: Self, x: i32, y: i32, w: u32, h: u32) bool {
    var dy: i32 = 0;
    while (dy < h) : (dy += 1) {
        var dx: i32 = 0;
        while (dx < w) : (dx += 1) {
            const xx = x + dx;
            const yy = y + dy;
            if (xx < 0 or
                xx >= w4.CANVAS_SIZE or
                yy < 0 or
                yy >= w4.CANVAS_SIZE)
                continue;
            const idx = @intCast(usize, xx + yy * w4.CANVAS_SIZE);
            if (s.walls.get(idx) == 1) return true;
        }
    }
    return false;
}

fn floorToInt(comptime T: type, x: f32) T {
    return @floatToInt(T, @floor(x));
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
    vx: f32 = 0,
    vy: f32 = 0,
    speed: f32 = 0.5,
    rot: u2 = 0,
    shootTimer: u32 = 0,
    sprite: *const Sprite,

    fn draw(self: Tank) void {
        self.sprite.drawRotated(
            floorToInt(i32, self.x),
            floorToInt(i32, self.y),
            self.rot,
        );
    }

    fn centerx(self: Tank) f32 {
        return self.x + @intToFloat(f32, self.sprite.w) / 2;
    }

    fn centery(self: Tank) f32 {
        return self.y + @intToFloat(f32, self.sprite.h) / 2;
    }
};
