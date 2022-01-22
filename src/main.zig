const std = @import("std");
const w4 = @import("wasm4.zig");
const rng = @import("rng.zig");
const MainScene = @import("MainScene.zig");
const MenuScene = @import("MenuScene.zig");

pub const Scene = union(enum) {
    MainScene: MainScene,
    MenuScene: MenuScene,

    fn update(self: *Scene) void {
        // waiting for https://github.com/ziglang/zig/issues/7224
        switch (self.*) {
            .MainScene => |*s| updateAndDraw(s),
            .MenuScene => |*s| updateAndDraw(s),
        }
    }

    fn updateAndDraw(s: anytype) void {
        s.update();
        s.draw();
    }
};

var currentScene: Scene = Scene{ .MenuScene = .{} };
pub var nextScene: ?Scene = null;

export fn start() void {}

export fn update() void {
    rng.update();
    if (nextScene) |s| {
        currentScene = s;
        nextScene = null;
    }
    currentScene.update();
}
