const std = @import("std");
pub fn is_directory(path: []const u8) bool {
    const stat = std.fs.cwd().statFile(path) catch return false;

    return stat.kind == .directory;
}
