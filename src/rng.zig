const std = @import("std");
const w4 = @import("wasm4.zig");

var frame: u64 = 0;
var rng_impl = std.rand.DefaultPrng.init(0xdeadbeef);
pub const rng = rng_impl.random();

pub fn update() void {
    // gather entropy from player inputs
    if (w4.GAMEPAD1.v != 0) {
        rng_impl.s[0] = hash(rng_impl.s[0] ^ w4.GAMEPAD1.v ^ (frame << 10));
    }
    if (w4.GAMEPAD2.v != 0) {
        rng_impl.s[2] = hash(rng_impl.s[2] ^ (@as(u64, w4.GAMEPAD1.v) << 35) ^ (frame << 24));
    }
    frame +%= 1;
}

// based on https://stackoverflow.com/a/70620975
pub fn hash(x: u64) u64 {
    var r = x;
    r ^= r >> 17;
    r *= 0xed5ad4bbac4c1b51;
    r ^= r >> 11;
    r *= 0xac4c1b5131848bab;
    r ^= r >> 15;
    r *= 0x31848babed5ad4bb;
    r ^= r >> 14;
    return r;
}
