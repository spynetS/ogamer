package ogamer_io;

import "core:mem/virtual"
import "core:fmt"

new_tilesheet :: proc  {
    new_tilesheet_path,
}
new_tilesheet_path :: proc (handler: ^AssetsManager, path: string, tile_size: [2]i32, box_offset: [2]i32 = {0,0}) -> (^TileSheet, bool) #optional_ok {
    sprite, ok := load(handler, path)
    if !ok do return nil, false

    texture := handler.textures[sprite.texture]

    columns := texture.width / (box_offset.x + tile_size.x)
    rows    := texture.height / (box_offset.y + tile_size.y)

    ts := new(TileSheet, allocator=virtual.arena_allocator(&handler.arena))
    ts.sprites = make([][]Sprite, rows, allocator=virtual.arena_allocator(&handler.arena))
    ts.size = tile_size

    tex_w := f32(texture.width)
    tex_h := f32(texture.height)

    for r in 0..<rows {

        ts.sprites[r] = make([]Sprite, columns,allocator=virtual.arena_allocator(&handler.arena))

        for c in 0..<columns {
            x := f32((box_offset.x + tile_size.x) * c)
            y := f32((box_offset.y + tile_size.y) * r)

            w := f32(tile_size.x)
            h := f32(tile_size.y)

            ts.sprites[r][c] = Sprite({
                texture = sprite.texture,
                uv = {
                    { x / tex_w,       y / tex_h       },
                    { (x+w) / tex_w,   (y+h) / tex_h   },
                },
            })
        }
    }
    return ts, true
}


merge_tilesheet :: proc(handler: ^AssetsManager, first, second: ^TileSheet) {
    alloc := virtual.arena_allocator(&handler.arena)

    new_rows := make([][]Sprite, len(first.sprites) + len(second.sprites), alloc)
    count := 0

    // copy first
    for r in 0..<len(first.sprites) {
        src := first.sprites[r]
        row := make([]Sprite, len(src), alloc) 
        copy(row, src)
        new_rows[count] = row
        count += 1
    }
    // copy second
    for r in 0..<len(second.sprites) {
        src := second.sprites[r]
        row := make([]Sprite, len(src), alloc)
        copy(row, src)
        new_rows[count] = row
        count += 1
    }

    first.sprites = new_rows
}
