const Self = @This();
const std = @import("std");
const w4 = @import("wasm4.zig");
const Sprite = @import("Sprite.zig");

const walls_size = 100;
const walls_color = 3;
const Walls = std.PackedIntArray(u1, walls_size * walls_size);

player1: Tank = Tank{
    .x = 10,
    .y = 70,
    .vx = 0,
    .vy = 0,
    .speed = 0.5,
    .rot = 0,
    .sprite = &Sprite.load("tank"),
},
// use `std.mem.zeroes` here because it makes compilation much faster than
// looping and setting all elements to 0
walls: Walls = std.mem.zeroes(Walls),
// TODO: gather entropy from player input
rng: std.rand.DefaultPrng = std.rand.DefaultPrng.init(0xdeadbeef),

pub fn init() Self {
    var s = Self{};
    s.generateWalls();
    return s;
}

pub fn update(s: *Self) void {
    updatePlayer(&s.player1, w4.GAMEPAD1.*);
}

pub fn draw(s: Self) void {
    w4.DRAW_COLORS.* = 2;
    w4.text("Hello from Zig!", 10, 10);
    s.drawWalls();
    s.player1.draw();
}

fn generateWalls(s: *Self) void {
    var x: usize = 0;
    while (x < walls_size) : (x += 1) {
        var y: usize = 0;
        while (y < walls_size) : (y += 1) {
            if (s.rng.random().float(f32) < 0.5) {
                s.walls.set(x + y * walls_size, 1);
            }
        }
    }
}

fn drawWalls(s: Self) void {
    var x: usize = 0;
    while (x < walls_size) : (x += 1) {
        var y: usize = 0;
        while (y < walls_size) : (y += 1) {
            if (s.walls.get(x + y * walls_size) == 1) {
                w4.setPixel(x + 30, y + 30, walls_color);
            }
        }
    }
}

fn updatePlayer(tank: *Tank, pad: w4.Gamepad) void {
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
    if (tank.vy < 0) {
        tank.rot = 0;
    } else if (tank.vx < 0) {
        tank.rot = 1;
    } else if (tank.vy > 0) {
        tank.rot = 2;
    } else if (tank.vx > 0) {
        tank.rot = 3;
    }
    var newx = tank.x + tank.vx;
    var newy = tank.y + tank.vy;
    if (!isColliding(newx + 1, newy + 1, 5, 5)) {
        tank.x = newx;
        tank.y = newy;
    }
}

fn isColliding(x: f32, y: f32, w: f32, h: f32) bool {
    if (x < 0 or x + w > w4.CANVAS_SIZE or y < 0 or y + h > w4.CANVAS_SIZE) {
        return true;
    }
    return false;
}

const Tank = struct {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
    speed: f32,
    rot: u2,
    sprite: *const Sprite,

    fn draw(self: Tank) void {
        self.sprite.drawRotated(
            @floatToInt(i32, self.x),
            @floatToInt(i32, self.y),
            self.rot,
        );
    }
};
