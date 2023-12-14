const std = @import("std");

const qc = @import("qc-build.zig");

pub fn build(b: *std.Build) void
{
    qc.init(b);

    qc.addModule(@import("modules/qc-core/module.zig"));
    qc.addModule(@import("modules/qc-image/module.zig"));

    qc.buildTests("qc-image");

    qc.buildExe("test/test.zig", &.{"qc-image"}, &.{}, &.{});
}
