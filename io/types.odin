package ogamer_io;

import "core:mem/virtual"

Vector2 :: [2]f32


Image :: struct {
    data : []u8,
    width, height, mipmaps, channels : i32,
}

UV :: distinct [2]Vector2

Texture_ID :: distinct string

Sprite :: struct {
    texture: Texture_ID,
    uv: UV
}

TileSheet :: struct {
    sprites: [][]Sprite,
    size: [2]i32 // the width and height for each tile
}


AssetsManager :: struct {
    textures: map[Texture_ID]^Image,
    id_counter: u32,
    arena: virtual.Arena

}
