package renderer;

get_color :: proc(c:u32) -> [4]u8 {
    return [4]u8{
        u8((c >> 24) & 0xFF),
        u8((c >> 16) & 0xFF),
        u8((c >> 8) & 0xFF),
        u8(c & 0xFF),
    }
}


