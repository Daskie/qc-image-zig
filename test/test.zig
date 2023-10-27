const std = @import("std");
const qc = struct
{
    usingnamespace @import("../modules/qc-core/qc-core.zig");
    const image = @import("../modules/qc-image/qc-image.zig");
};

pub fn main() !void
{
    // G
    {
        var image: qc.image.GImage = try qc.image.read("g-in.png", 1);
        defer image.deinit();

        try qc.image.writePng("g-out.png", 1, image);
    }

    // GA
    {
        var image: qc.image.GAImage = try qc.image.read("ga-in.png", 2);
        defer image.deinit();

        try qc.image.writePng("ga-out.png", 2, image);
    }

    // RGB
    {
        var image: qc.image.RGBImage = try qc.image.read("rgb-in.png", 3);
        defer image.deinit();

        try qc.image.writePng("rgb-out.png", 3, image);
    }

    // RGBA
    {
        var image: qc.image.RGBAImage = try qc.image.read("rgba-in.png", 4);
        defer image.deinit();

        try qc.image.writePng("rgba-out.png", 4, image);
    }
}
