const Self = @This();
const std = @import("std");
const hash = @import("rng.zig").hash;

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
            const rx = gx - fx;
            const ry = gy - fy;
            const d = rx * rx + ry * ry;
            const w = 1.0 - smoothstep(0.0, 1.414, @sqrt(d));
            va += w * @intToFloat(f32, hash(
                ((@as(u64, @bitCast(u32, px + gx)) << 32) |
                    @bitCast(u32, py + gy)) ^ s.seed,
            )) / 0xffffffffffffffff;
            wt += w;
        }
    }
    return va / wt;
}

// from https://en.wikipedia.org/wiki/Smoothstep
fn smoothstep(edge0: f32, edge1: f32, x: f32) f32 {
    // Scale, bias and saturate x to 0..1 range
    var xx = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    // Evaluate polynomial
    return xx * xx * (3 - 2 * xx);
}

fn clamp(x: f32, lowerlimit: f32, upperlimit: f32) f32 {
    if (x < lowerlimit)
        return lowerlimit;
    if (x > upperlimit)
        return upperlimit;
    return x;
}
