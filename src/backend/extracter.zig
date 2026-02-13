const std = @import("std");
const print = std.debug.print;

const comp = @import("../utils/comparators.zig");
const r = @import("../utils/readers.zig");

const Entry = struct {
    path: []const u8,
    size: u64,
    offset: u64,
};

pub fn extract(pfs_dir: []const u8, out_dir: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var entries = std.ArrayList(Entry).init(alloc);
    defer {
        for (entries.items) |e| {
            alloc.free(e.path);
        }

        entries.deinit();
    }

    const file = try std.fs.cwd().openFile(pfs_dir, .{ .mode = .read_only });
    defer file.close();

    const reader = file.reader();

    var magic: [4]u8 = undefined;
    try reader.readNoEof(&magic);

    if (!comp.equals(magic[0..], "PFS0")) {
        print("ERRO: o arquivo '{s}' não é um .pfs válido.\n", .{pfs_dir});
        return;
    }

    const version = try r.read_u16_LE(reader);
    _ = version;

    const count = try r.read_u32_LE(reader);

    var i: u32 = 0;
    var buffer: [4096]u8 = undefined;

    while (i < count) {
        const path_len = try r.read_u16_LE(reader);
        if (path_len == 0 or path_len >= buffer.len) {
            print("ERRO: path_len inválido ({d})\n", .{path_len});
            return;
        }

        const path_sliced = buffer[0..path_len];
        try reader.readNoEof(path_sliced);

        const path_copy = try alloc.dupe(u8, path_sliced);
        const size = try r.read_u64_LE(reader);
        const offset = try r.read_u64_LE(reader);

        try entries.append(Entry{
            .path = path_copy,
            .size = size,
            .offset = offset,
        });

        i += 1;
    }

    std.fs.cwd().makeDir(out_dir) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };
    var out = try std.fs.cwd().openDir(out_dir, .{});
    defer out.close();

    var chunk: [64 * 1024]u8 = undefined;
    for (entries.items) |e| {
        if (std.mem.startsWith(u8, e.path, "/") or std.mem.indexOf(u8, e.path, "..") != null) {
            print("ERRO: path inseguro no pacote: {s}\n", .{e.path});
            return;
        }

        if (std.fs.path.dirname(e.path)) |d| {
            try out.makePath(d);
        }

        var f = try out.createFile(e.path, .{ .truncate = true });
        defer f.close();

        try file.seekTo(e.offset);

        var remaning: u64 = e.size;
        while (remaning > 0) {
            const want: usize = @intCast(@min(remaning, chunk.len));
            const n = try file.read(chunk[0..want]);

            if (n == 0) {
                return error.UnexpectedEof;
            }

            try f.writeAll(chunk[0..n]);

            remaning -= n;
        }
    }
}
