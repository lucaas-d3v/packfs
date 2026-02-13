const std = @import("std");
const print = std.debug.print;

// internal imports
const comp = @import("../utils/comparators.zig");
const r = @import("../utils/readers.zig");

pub fn list(pfs_file_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(pfs_file_path, .{ .mode = .read_only });
    defer file.close();

    // const buffer: [2048]u8 = undefined;
    const reader = file.reader();

    var magic: [4]u8 = undefined;
    try reader.readNoEof(&magic);

    if (!comp.equals(magic[0..], "PFS0")) {
        print("ERRO: o arquivo '{s}' não é um .pfs válido.\n", .{pfs_file_path});
        return;
    }

    const version = try r.read_u16_LE(reader);
    const count = try r.read_u32_LE(reader);

    print("{d}, {d}\n", .{ version, count });

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

        const size = try r.read_u64_LE(reader);
        const offset = try r.read_u64_LE(reader);

        print("{s} {d} {d}\n", .{ path_sliced, size, offset });
        i += 1;
    }
}
