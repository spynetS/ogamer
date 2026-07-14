package file_io;

import "../types"
import "core:mem/virtual"

new_tilesheet :: proc  {
    new_tilesheet_path,
}
new_tilesheet_path :: proc (handler: ^types.IOHandler, path: string, tile_size: [2]i32, box_offset: [2]i32 = {0,0}) -> (^types.TileSheet, bool) #optional_ok {
    sprite, ok := load(handler, path)
    if !ok do return nil, false

    texture := handler.textures[sprite.texture]

    columns := texture.width / (box_offset.x + tile_size.x)
    rows    := texture.height / (box_offset.y + tile_size.y)

    ts := new(types.TileSheet, allocator=virtual.arena_allocator(&handler.arena))
    ts.sprites = make([][]types.Sprite, rows, allocator=virtual.arena_allocator(&handler.arena))
    ts.size = tile_size

    tex_w := f32(texture.width)
    tex_h := f32(texture.height)

    for r in 0..<rows {

        ts.sprites[r] = make([]types.Sprite, columns,allocator=virtual.arena_allocator(&handler.arena))

        for c in 0..<columns {
            x := f32((box_offset.x + tile_size.x) * c)
            y := f32((box_offset.y + tile_size.y) * r)

            w := f32(tile_size.x)
            h := f32(tile_size.y)

            ts.sprites[r][c] = types.Sprite({
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


// new_tilesheet_textire :: proc (image: ^types.Image, tile_size: [2]i32, box_offset:[2]i32 = {0,0}) -> (^types.TileSheet, bool) #optional_ok {
//     columns := image.width / (box_offset.x+ tile_size.x);
//     rows    := image.height / (box_offset.y+tile_size.y);

//     ts := new(types.TileSheet)
//     ts.images = make([][]^types.Image, rows)
//     ts.size = tile_size;


//     for r in 0..<rows {
//         ts.images[r] = make([]^types.Image, columns)
//         for c in 0..<columns {
//             croped, ok := crop(image, c*(box_offset.x+tile_size.x), (box_offset.y+tile_size.y)*r, tile_size.x, tile_size.y);
//             if !ok do return nil, false
//             ts.images[r][c] = croped
//         }
//     } 
//     return ts, true
// }

// copy_image :: proc(dst, src: ^types.Image) {
//     size := int(src.width * src.height * src.channels);
//     dst.data = make([]u8, size)
//     copy(dst.data, src.data)
//     dst.width    = src.width
//     dst.height   = src.height
//     dst.channels = src.channels
//     dst.mipmaps  = src.mipmaps
// }

/** will add a new rows in the @param first from the second */
// merge_tilesheet :: proc(first, second: ^types.TileSheet) {
//     new_rows := make([][]^types.Image, len(first.images)+len(second.images))
//     count := 0
//     // insert the first first
//     for r in 0..<len(first.images) {
//         new_rows[count] = first.images[r]
//         count += 1
//     }
//     // insert the second
//     for r in 0..<len(second.images) {
//         row := make([]^types.Image, len(second.images[r]))
//         for c in 0..<len(second.images[r]) {
//             fmt.println("second",c)
//             row[c] = new(types.Image);
//             copy_image(row[c], second.images[r][c]);
//         }
//         new_rows[count] = row;
//         count += 1
//     }
//     delete(first.images)
//     first.images = new_rows
// }
