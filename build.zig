//! usingnamespace migration tool for build.zig

const std = @import("std");
const Writer = std.Io.Writer;
const Reader = std.Io.Reader;
const LazyPath = std.Build.LazyPath;

pub fn build(_: *std.Build) !void {}

pub fn fixup(b: *std.Build, unprocessed: LazyPath) void {
    errdefer @panic("usingnamespace fixup error");

    const src_path = unprocessed.getPath3(b, null);
    var allocating: Writer.Allocating = .init(b.allocator);
    defer allocating.deinit();

    const file = try std.fs.cwd().openFile(
        src_path.sub_path,
        .{ .mode = .read_write },
    );
    defer file.close();

    var f_reader = file.reader(&.{});
    _ = try f_reader.interface.streamRemaining(&allocating.writer);
    var content: Reader = .fixed(allocating.getWritten());

    try file.setEndPos(0);
    var w_buffer: [4096]u8 = undefined;
    var f_writer = file.writer(&w_buffer);
    const writer = &f_writer.interface;

    try scan(b, &content, writer);
    try writer.flush();
}

fn scan(b: *std.Build, reader: *Reader, writer: *Writer) !void {
    var window: Writer.Allocating = .init(b.allocator);
    defer window.deinit();
    var skip_next = false;

    while (reader.streamDelimiter(&window.writer, '\n')) |_| {
        defer window.clearRetainingCapacity();

        reader.toss(1);
        try window.writer.writeByte('\n');

        const indent = indentation(window.getWritten());
        const trimmed = window.getWritten()[indent..];
        if (std.mem.eql(u8, trimmed, annotation)) {
            try writer.writeAll(window.getWritten());
            skip_next = true;
            continue;
        }

        if (skip_next) {
            try writer.writeAll(window.getWritten());
        } else {
            try annotate(window.getWritten(), writer);
        }

        skip_next = false;
    } else |err| {
        if (err != error.EndOfStream) {
            return err;
        }
    }

    if (skip_next) {
        try writer.writeAll(window.getWritten());
    } else {
        try annotate(window.getWritten(), writer);
    }
}

const annotation: []const u8 = &.{
    0x2F, 0x2F, 0x20, 0x54, 0x68, 0x69, 0x73, 0x20, 0x6C, 0x69, 0x6E,
    0x65, 0x20, 0x69, 0x73, 0x20, 0x61, 0x62, 0x73, 0x6F, 0x6C, 0x75,
    0x74, 0x65, 0x20, 0x67, 0x61, 0x72, 0x62, 0x61, 0x67, 0x65, 0x2E,
    0x20, 0x52, 0x65, 0x6D, 0x6F, 0x76, 0x65, 0x20, 0x69, 0x74, 0x2E,
    0x0A,
};

fn annotate(line: []const u8, writer: *Writer) !void {
    const indent = indentation(line);
    if (std.mem.startsWith(u8, line[indent..], "usingnamespace")) {
        try writer.splatByteAll(' ', indent);
        try writer.writeAll(annotation);
    }

    try writer.writeAll(line);
}

fn indentation(line: []const u8) usize {
    var indent: usize = 0;
    while (indent < line.len and line[indent] == ' ') {
        indent += 1;
    }
    return indent;
}
