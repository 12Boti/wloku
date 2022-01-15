const Self = @This();
const std = @import("std");
const hash = @import("rng.zig").hash;
const distSq = @import("math.zig").distSq;

seed: u64,

pub fn init(seed: u64) Self {
    return Self{
        .seed = seed,
    };
}

// based on https://iquilezles.org/www/articles/voronoise/voronoise.htm
pub fn get(s: Self, x: f32, y: f32) f32 {
    const px = @floor(x);
    const py = @floor(y);
    const fx = x - px;
    const fy = y - py;

    var va: f32 = 0.0;
    var wt: f32 = 0.0;
    var j: i8 = -2;
    while (j <= 2) : (j += 1) {
        var i: i8 = -2;
        while (i <= 2) : (i += 1) {
            const gx = @intToFloat(f32, i);
            const gy = @intToFloat(f32, j);
            const d = distSq(f32, gx, gy, fx, fy);
            const w = 1.0 - smoothstep(0.0, 1.414, @sqrt(d));
            va += w * hash2f(px + gx, py + gy, s.seed);
            wt += w;
        }
    }
    return va / wt;
}

fn hash2f(x: f32, y: f32, extra: u64) f32 {
    const p = ((@as(u64, @bitCast(u32, x)) << 32) | @bitCast(u32, y)) ^ extra;
    return @intToFloat(f32, hash(p)) / std.math.maxInt(u64);
}

// from https://en.wikipedia.org/wiki/Smoothstep
fn smoothstep(edge0: f32, edge1: f32, x: f32) f32 {
    // Scale, bias and saturate x to 0..1 range
    var xx = std.math.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    // Evaluate polynomial
    return xx * xx * (3 - 2 * xx);
}
