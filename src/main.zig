const std = @import("std");
const w4 = @import("wasm4.zig");
const MainScene = @import("MainScene.zig");

const Scene = union(enum) {
    MainScene: MainScene,

    fn update(self: *Scene) void {
        // waiting for https://github.com/ziglang/zig/issues/7224
        switch (self.*) {
            .MainScene => |*s| updateAndDraw(s),
        }
    }

    fn updateAndDraw(s: anytype) void {
        s.update();
        s.draw();
    }
};

var currentScene: Scene = undefined;

export fn start() void {
    currentScene = Scene{ .MainScene = MainScene.init() };
}

export fn update() void {
    currentScene.update();
}
