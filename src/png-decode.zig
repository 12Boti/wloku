const std = @import("std");
const c = @cImport({
    @cInclude("lodepng.h");
});

pub fn main() !void {
    var args = std.process.ArgIteratorPosix.init();
    _ = args.skip();
    var data: ?[*]u8 = null;
    var w: c_uint = undefined;
    var h: c_uint = undefined;
    const ret = c.lodepng_decode_file(
        &data,
        &w,
        &h,
        args.next() orelse return error.TooFewArguments,
        c.LCT_PALETTE,
        8,
    );
    if (ret != 0) {
        std.process.exit(1);
    }
    var f = try std.fs.cwd().createFile(
        args.next() orelse return error.TooFewArguments,
        .{},
    );
    defer f.close();
    var writer = f.writer();
    try writer.writeByte(@intCast(u8, w));
    try writer.writeByte(@intCast(u8, h));
    try writer.writeAll(data.?[0 .. w * h]);
}
