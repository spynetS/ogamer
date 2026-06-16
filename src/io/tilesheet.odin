package file_io;

import "../ecs/types"
import "core:fmt"

new_tilesheet :: proc (image: ^types.Image, tile_size: [2]i32, box_offset:[2]i32 = {0,0}) -> ^types.TileSheet {
    columns := image.width / (box_offset.x+ tile_size.x);
    rows    := image.height / (box_offset.y+tile_size.y);

    ts := new(types.TileSheet)
    ts.images = make([][]^types.Image, rows)
    ts.size = tile_size;


    for r in 0..<rows {
        ts.images[r] = make([]^types.Image, columns)
        for c in 0..<columns {
            croped := crop(image, c*(box_offset.x+tile_size.x), (box_offset.y+tile_size.y)*r, tile_size.x, tile_size.y);
            ts.images[r][c] = croped
        }
    } 
    return ts
}

copy_image :: proc(dst, src: ^types.Image) {
    size := int(src.width * src.height * src.channels);
    dst.data = make([]u8, size)
    copy(dst.data, src.data)
    dst.width    = src.width
    dst.height   = src.height
    dst.channels = src.channels
    dst.mipmaps  = src.mipmaps
}

/** will add a new rows in the @param first from the second */
merge_tilesheet :: proc(first, second: ^types.TileSheet) {
    new_rows := make([][]^types.Image, len(first.images)+len(second.images))
    count := 0
    // insert the first first
    for r in 0..<len(first.images) {
        new_rows[count] = first.images[r]
        count += 1
    }
    // insert the second
    for r in 0..<len(second.images) {
        row := make([]^types.Image, len(second.images[r]))
        for c in 0..<len(second.images[r]) {
            fmt.println("second",c)
            row[c] = new(types.Image);
            copy_image(row[c], second.images[r][c]);
        }
        new_rows[count] = row;
        count += 1
    }
    delete(first.images)
    first.images = new_rows
}


free_tilesheet :: proc(ts: ^types.TileSheet) {
    for r in 0..<len(ts.images) {
        //ts.images[r] = make([]^types.Image, columns)
        for c in 0..<len(ts.images[r]) {
            free_image(ts.images[r][c]);
        }
        delete(ts.images[r])
    }
    delete(ts.images);
    free(ts)
}
