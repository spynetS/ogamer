package file_io;

import "../ecs/types"
import "core:fmt"

new_tilesheet :: proc (image: ^types.Image, s: [2]i32) -> ^types.TileSheet {
    columns := image.width / s.x;
    rows    := image.height / s.y;

    ts := new(types.TileSheet)
    ts.images = make([][]^types.Image, rows)
    ts.size = s;


    for r in 0..<rows {
        ts.images[r] = make([]^types.Image, columns)
        for c in 0..<columns {
            croped := crop(image, c*s.x, r*s.y, s.x, s.y);
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
