const std = @import("std");
const print = std.debug.print;

// internal imports
const comp = @import("../utils/comparators.zig");

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

    const version = try read_u16_LE(reader);
    const count = try read_u32_LE(reader);

    print("{d}, {d}\n", .{ version, count });

    var i: u32 = 0;
    var buffer: [4096]u8 = undefined;

    while (i < count) {
        const path_len = try read_u16_LE(reader);
        if (path_len == 0 or path_len >= buffer.len) {
            print("ERRO: path_len inválido ({d})\n", .{path_len});
            return;
        }

        const path_sliced = buffer[0..path_len];
        try reader.readNoEof(path_sliced);

        const size = try read_u64_LE(reader);
        const offset = try read_u64_LE(reader);

        print("{s} {d} {d}\n", .{ path_sliced, size, offset });
        i += 1;
    }
}

// utilitys
fn read_u16_LE(r: anytype) !u16 {
    return try r.readInt(u16, .little);
}

fn read_u32_LE(r: anytype) !u32 {
    return try r.readInt(u32, .little);
}

fn read_u64_LE(r: anytype) !u64 {
    return try r.readInt(u64, .little);
}
