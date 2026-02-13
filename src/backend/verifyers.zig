const std = @import("std");

pub fn is_directory(path: []const u8) bool {
    const stat = std.fs.cwd().statFile(path) catch return false;
    return stat.kind == .directory;
}

pub fn ensure_directory(path: []const u8) !void {
    std.fs.cwd().makePath(path) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };
}
