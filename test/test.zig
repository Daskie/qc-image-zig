const std = @import("std");
const qc = struct
{
    usingnamespace @import("qc-core");
    const image = @import("qc-image");
};

pub fn main() !void
{
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const data: []u8 = try qc.readFile("g-in.png", allocator);
    defer _ = allocator.free(data);

    const image: qc.image.GImage = try qc.image.decode(1, data);
    defer image.deinit();

    const encodedData: []u8 = try qc.image.encodePng(1, image);

    try qc.writeFile("g-out.png", encodedData);
}
