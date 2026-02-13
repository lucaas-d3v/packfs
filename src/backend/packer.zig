const std = @import("std");

const Entry = struct {
    path: []const u8,
    size: u64,
    offset: u64,
};

pub fn pack(dir_path: []const u8, out_name: []const u8, recursive: bool) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const out_name_ = try normalize(alloc, out_name);
    defer alloc.free(out_name_);

    var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer dir.close();

    var arquivos = try dir.walk(alloc);
    defer arquivos.deinit();

    var entries = std.ArrayList(Entry).init(alloc);
    defer {
        for (entries.items) |e| alloc.free(e.path);
        entries.deinit();
    }

    // 1ª passada
    while (try arquivos.next()) |arquivo| {
        if (arquivo.kind == .directory) {
            continue;
        }

        // Se não é recursivo, ignora arquivos em subdiretórios
        if (!recursive and std.mem.indexOf(u8, arquivo.path, "/") != null) {
            continue; // Tem '/' no caminho = está em subdiretório
        }

        // Ignora o arquivo de saída
        if (std.mem.eql(u8, arquivo.path, out_name_)) {
            continue;
        }

        if (arquivo.kind != .file) {
            continue;
        }

        const stats = try dir.statFile(arquivo.path);
        const r_path = try alloc.dupe(u8, arquivo.path);

        try entries.append(Entry{
            .path = r_path,
            .size = stats.size,
            .offset = 0,
        });
    }

    // 2ªpassada
    const header_size: u64 = 4 + 2 + 4;

    var table_size_total: u64 = 0;
    for (entries.items) |e| {
        if (e.path.len == 0 or e.path.len >= 4096) {
            return error.InvalidPathLen;
        }

        if (e.path.len > std.math.maxInt(u16)) {
            return error.InvalidPathLen;
        }

        table_size_total += 2;
        table_size_total += @as(u64, e.path.len);
        table_size_total += 8;
        table_size_total += 8;
    }

    var current_offset: u64 = header_size + table_size_total;

    for (entries.items) |*e| {
        e.offset = current_offset;
        current_offset += e.size;
    }

    const out_file = try std.fs.cwd().createFile(out_name_, .{ .truncate = true });
    defer out_file.close();

    var writer = out_file.writer();

    // HEADER
    try writer.writeAll("PFS0");
    try writer.writeInt(u16, 1, .little);
    try writer.writeInt(u32, @intCast(entries.items.len), .little);

    // TABLE
    for (entries.items) |e| {
        try writer.writeInt(u16, @intCast(e.path.len), .little);
        try writer.writeAll(e.path);
        try writer.writeInt(u64, e.size, .little);
        try writer.writeInt(u64, e.offset, .little);
    }

    // DADOS
    var buf: [64 * 1024]u8 = undefined;
    for (entries.items) |e| {
        var in_file = try dir.openFile(e.path, .{ .mode = .read_only });
        defer in_file.close();

        while (true) {
            const n = try in_file.read(&buf);

            if (n == 0) {
                break;
            }

            try writer.writeAll(buf[0..n]);
        }
    }
}

fn normalize(allocator: std.mem.Allocator, name: []const u8) ![]const u8 {
    if (!std.mem.endsWith(u8, name, ".pfs")) {
        return try std.fmt.allocPrint(allocator, "{s}.pfs", .{name});
    }
    return try allocator.dupe(u8, name); // Para consistência de ownership
}
