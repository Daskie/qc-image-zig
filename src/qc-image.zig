const std = @import("std");
const qc = @import("qc-core");

// For some reason stb_image_write.h doesn't expose the stbi_write_to_mem definitions, so we're forward declaring
extern fn stbi_load_from_memory(buffer: [*c]const u8, len: c_int, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]u8;
extern fn stbi_write_png_to_mem(pixels: [*c]const u8, stride_bytes: c_int, x: c_int, y: c_int, n: c_int, out_len: [*c]c_int) [*c]u8;

pub fn Image(comptime n: u8) type
{
    return struct
    {
        size: qc.UVec2,
        data: [*]Pixel,

        pub const Pixel = if (n == 1) u8 else qc.U8Vec(n);

        pub fn deinit(this: @This()) void
        {
            std.heap.raw_c_allocator.free(this.data[0..this.size.x * this.size.y * @sizeOf(Pixel)]);
        }
    };
}

pub const GImage = Image(1);
pub const GAImage = Image(2);
pub const RGBImage = Image(3);
pub const RGBAImage = Image(4);

/// Returned memory must be freed with C allocator
pub fn decode(comptime expectedComponentN: u8, data: []const u8) !Image(expectedComponentN)
{
    // Load image metrics
    var width: c_int = 0;
    var height: c_int = 0;
    var actualComponentN: c_int = 0;
    const decodedData: ?[*]u8 = stbi_load_from_memory(data.ptr, @intCast(data.len), &width, &height, &actualComponentN, 0);

    if (decodedData == null)
    {
        return error.DecodeError;
    }

    // Validate image metrics
    if (width <= 0 or height <= 0 or actualComponentN != expectedComponentN)
    {
        return error.InvalidImageMetrics;
    }

    return Image(expectedComponentN){.size = .{.x = @intCast(width), .y = @intCast(height)}, .data = decodedData.?};
}

pub fn encodePng(comptime componentN: u8, image: Image(componentN)) ![]u8
{
    var encodedDataBytes: c_int = 0;
    const encodedData: ?[*]u8 = stbi_write_png_to_mem(image.data, @intCast(image.size.x * @sizeOf(Image(componentN).Pixel)), @intCast(image.size.x), @intCast(image.size.y), componentN, &encodedDataBytes);

    if (encodedData == null)
    {
        return error.EncodeError;
    }

    return encodedData.?[0..@intCast(encodedDataBytes)];
}
