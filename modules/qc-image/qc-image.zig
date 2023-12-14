const std = @import("std");

const qc = @import("../qc-core/qc-core.zig");

const UVec2 = qc.UVec2;

// For some reason stb_image_write.h doesn't expose the stbi_write_to_mem definitions, so we're forward declaring
extern fn stbi_load_from_memory(buffer: [*c]const u8, len: c_int, x: [*c]c_int, y: [*c]c_int, channels_in_file: [*c]c_int, desired_channels: c_int) [*c]u8;
extern fn stbi_write_png_to_mem(pixels: [*c]const u8, stride_bytes: c_int, x: c_int, y: c_int, n: c_int, out_len: [*c]c_int) [*c]u8;

pub fn Image(comptime n: u8) type
{
    return struct
    {
        size: UVec2,
        pixels: []Pixel,

        pub const componentN = n;
        pub const Pixel = if (componentN == 1) u8 else qc.U8Vec(componentN);

        pub fn init(size: UVec2) @This()
        {
            return @This(){.size = size, .pixels = std.heap.raw_c_allocator.alloc(Pixel, size.x * size.y) catch unreachable};
        }

        pub fn deinit(this: *@This()) void
        {
            std.heap.raw_c_allocator.free(this.pixels[0..(this.size.x * this.size.y)]);
        }

        pub inline fn row(this: @This(), y: u32) []Pixel
        {
            const startI = (this.size.y - 1 - y) * this.size.x;
            return this.pixels[startI..(startI + this.size.x)];
        }

        pub inline fn at(this: @This(), p: UVec2) *Pixel
        {
            return &this.row(p.y)[p.x];
        }

        pub inline fn view(this: *const @This(), pos: UVec2, size: UVec2) View
        {
            return View{.image = this, .pos = pos, .size = size};
        }

        pub inline fn fullView(this: *const @This()) View
        {
            return View{.image = this, .pos = UVec2{}, .size = this.size};
        }

        pub const View = struct
        {
            image: *const Image(n),
            pos: UVec2,
            size: UVec2,

            pub inline fn view(this: @This(), pos: UVec2, size: UVec2) View
            {
                return View{.image = this.image, .pos = this.pos.add(pos), .size = size};
            }

            pub inline fn row(this: @This(), y: u32) []Pixel
            {
                return this.image.row(this.pos.y + y)[this.pos.x..(this.pos.x + this.size.x)];
            }

            pub inline fn at(this: @This(), p: UVec2) *Pixel
            {
                return &this.row(p.y)[p.x];
            }

            pub fn fill(this: @This(), color: Pixel) void
            {
                var r = this.row(0);
                for (0..this.size.y) |_|
                {
                    @memset(r, color);
                    r.ptr -= this.image.size.x;
                }
            }

            pub fn copy(dst: @This(), src: @This()) void
            {
                const copySize = src.size.min(dst.size);
                var srcR: []Pixel = src.row(0)[0..copySize.x];
                var dstR: []Pixel = dst.row(0)[0..copySize.x];
                for (0..copySize.y) |_|
                {
                    @memcpy(dstR, srcR);
                    srcR.ptr -= src.image.size.x;
                    dstR.ptr -= dst.image.size.x;
                }
            }

            pub fn horizontalLine(this: @This(), pos: UVec2, length: u32, color: Pixel) void
            {
                if (pos.y < this.size.y)
                {
                    const startX: u32 = qc.clamp(pos.x, 0, this.size.x);
                    const endX: u32 = qc.clamp(pos.x + length, 0, this.size.x);
                    const r: []Pixel = this.row(pos.y)[startX..endX];
                    @memset(r, color);
                }
            }

            pub fn verticalLine(this: @This(), pos: UVec2, length: u32, color: Pixel) void
            {
                if (pos.x < this.size.x)
                {
                    const startY: u32 = qc.clamp(pos.y, 0, this.size.y);
                    const endY: u32 = qc.clamp(pos.y + length, 0, this.size.y);
                    var p: [*]Pixel = @ptrCast(this.at(UVec2.init(pos.x, startY)));
                    for (startY..endY) |_|
                    {
                        p[0] = color;
                        p -= this.image.size.x;
                    }
                }
            }

            pub fn outline(this: @This(), thickness: u32, color: Pixel) void
            {
                std.debug.assert(thickness > 0);

                this.horizontalLine(UVec2{}, this.size.x, color);
                if (this.size.y > 1)
                {
                    this.horizontalLine(UVec2.init(0, this.size.y - 1), this.size.x, color);
                    this.verticalLine(UVec2.init(0, 1), this.size.y - 2, color);
                    this.verticalLine(UVec2.init(this.size.x - 1, 1), this.size.y - 2, color);
                }

                if (thickness > 1 and this.size.x > 2 and this.size.y > 2)
                {
                    this.view(UVec2.all(1), this.size.sub(2)).outline(thickness - 1, color);
                }
            }

            pub fn checkerboard(this: @This(), squareSize: u32, evenColor: Pixel, oddColor: Pixel) void
            {
                std.debug.assert(squareSize > 0);

                var y: u32 = 0;
                var rowPixels: []Pixel = this.row(0);
                var rowEven: bool = true;
                yLoop: while (true) : (rowEven = !rowEven)
                {
                    for (0..squareSize) |_|
                    {
                        var x: u32 = 0;
                        var squareEven: bool = rowEven;
                        xLoop: while (true) : (squareEven = !squareEven)
                        {
                            const color = if (squareEven) evenColor else oddColor;
                            for (0..squareSize) |_|
                            {
                                rowPixels[x] = color;

                                x += 1;
                                if (x >= this.size.x) break :xLoop;
                            }
                        }

                        y += 1;
                        rowPixels.ptr -= this.image.size.x;
                        if (y >= this.size.y) break :yLoop;
                    }
                }
            }
        };
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

    const size = UVec2{.x = @intCast(width), .y = @intCast(height)};
    return Image(expectedComponentN){
        .size = size,
        .pixels = @as([*]Image(expectedComponentN).Pixel, @ptrCast(@alignCast(decodedData.?)))[0..(size.x * size.y)]};
}

pub fn encodePng(comptime componentN: u8, image: Image(componentN)) ![]u8
{
    var encodedDataBytes: c_int = 0;
    const encodedData: ?[*]u8 = stbi_write_png_to_mem(@ptrCast(image.pixels.ptr), @intCast(image.size.x * @sizeOf(Image(componentN).Pixel)), @intCast(image.size.x), @intCast(image.size.y), componentN, &encodedDataBytes);

    if (encodedData == null)
    {
        return error.EncodeError;
    }

    return encodedData.?[0..@intCast(encodedDataBytes)];
}

pub fn read(path: []const u8, comptime expectedComponentN: u8) !Image(expectedComponentN)
{
    var encodedData = try qc.readFile(path);
    return decode(expectedComponentN, encodedData);
}

pub fn writePng(path: []const u8, comptime componentN: u8, image: Image(componentN)) !void
{
    var encodedData = try encodePng(componentN, image);
    defer std.heap.raw_c_allocator.free(encodedData);
    try qc.writeFile(path, encodedData);
}
