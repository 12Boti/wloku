const Self = @This();
const std = @import("std");

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
            va += w * @intToFloat(f32, s.hash(
                (@as(u64, @bitCast(u32, px + gx)) << 32) |
                    @bitCast(u32, py + gy),
            )) / 0xffffffffffffffff;
            wt += w;
        }
    }
    return va / wt;
}

// based on https://stackoverflow.com/a/70620975
fn hash(s: Self, x: u64) u64 {
    var r = x ^ s.seed;
    r ^= r >> 17;
    r *= 0xed5ad4bbac4c1b51;
    r ^= r >> 11;
    r *= 0xac4c1b5131848bab;
    r ^= r >> 15;
    r *= 0x31848babed5ad4bb;
    r ^= r >> 14;
    return r;
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
