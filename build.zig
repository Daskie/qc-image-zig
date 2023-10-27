const std = @import("std");

const qc = @import("qc-build.zig");

pub fn build(b: *std.Build) void
{
    qc.addModule(b, @import("modules/qc-core/module.zig"));
    qc.addModule(b, @import("modules/qc-image/module.zig"));

    qc.buildTests("qc-image");

    qc.buildExe("test/test.zig", &.{"qc-image"}, &.{});
}
