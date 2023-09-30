const std = @import("std");
const qc = struct
{
    usingnamespace @import("deps/qc-build/build.zig");
    const core = @import("deps/qc-core/build.zig");
};

pub const info = .{
    .name = "qc-image",
    .cFiles = &.{"deps/stb/stb_image.c", "deps/stb/stb_image_write.c"},
    .deps = &.{"qc-core"}};

pub fn build(b: *std.Build) void
{
    qc.init(b, info, &.{qc.core.info});

    qc.buildPackageTests();

    qc.buildExe("test/test.zig", &.{"qc-image"}, &.{});
}
