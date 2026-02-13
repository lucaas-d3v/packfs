pub fn read_u16_LE(r: anytype) !u16 {
    return try r.readInt(u16, .little);
}

pub fn read_u32_LE(r: anytype) !u32 {
    return try r.readInt(u32, .little);
}

pub fn read_u64_LE(r: anytype) !u64 {
    return try r.readInt(u64, .little);
}
