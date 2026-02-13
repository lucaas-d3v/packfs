const std = @import("std");

pub fn equals(strA: []const u8, strB: []const u8) bool {
    return std.mem.eql(u8, strA, strB);
}

pub fn equals_command(strA: []const u8, commands: []const []const u8) bool {
    for (commands) |value| {
        if (std.mem.eql(u8, strA, value)) {
            return true;
        }
    }

    return false;
}
