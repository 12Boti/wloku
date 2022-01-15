pub fn distSq(comptime T: type, x1: T, y1: T, x2: T, y2: T) T {
    return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
}
