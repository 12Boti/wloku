const Self = @This();
const w4 = @import("wasm4.zig");
const main = @import("main.zig");
const MainScene = @import("MainScene.zig");

playSounds: bool = true,
selected: i8 = 0,
prevPad: w4.Gamepad = w4.Gamepad{ .v = 0 },

pub fn update(s: *Self) void {
    const pad = w4.GAMEPADS[0];
    if (pad.up() and !s.prevPad.up()) {
        s.selected -= 1;
    }
    if (pad.down() and !s.prevPad.down()) {
        s.selected += 1;
    }
    s.selected = @mod(s.selected, 2);
    if (s.prevPad.b1() and !pad.b1()) {
        switch (s.selected) {
            0 => main.currentScene = main.Scene{ .MainScene = MainScene.init(s.playSounds) },
            1 => s.playSounds = !s.playSounds,
            else => unreachable,
        }
    }
    s.prevPad = pad;
}
pub fn draw(s: Self) void {
    w4.DRAW_COLORS.* = 3;
    w4.text("WLOKU", 60, 10);
    w4.text(if (s.playSounds) "Yes" else "No", 95, 80);
    w4.DRAW_COLORS.* = 2;
    w4.text("Start game", 40, 60);
    w4.text("Sound:", 40, 80);
    w4.text(">", 30, 60 + s.selected * 20);
}
