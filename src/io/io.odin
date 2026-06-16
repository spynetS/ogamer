package file_io;

import "vendor:stb/image"
import "core:strings"
import "core:mem"

import "../ecs/types"

add :: proc(handler : ^types.IOHandler, file_path: string) -> (^types.Image, bool){
    image, ok := load(file_path)
    if ok do handler.images[file_path] = image
    return image, true
}

get :: proc(handler : ^types.IOHandler, file_path: string) -> (^types.Image, bool){
    if handler == nil do return nil, false
    image, ok := handler.images[file_path]
    if !ok {
        return load(file_path)
    }
    return image, ok
}
/** Returns new pointer to new image FREE IT */
crop :: proc(image: ^types.Image,x0, y0, w, h: i32) -> ^types.Image {
    
    sub : []u8 = make([]u8, w * h * image.channels)

    for y in 0..<h {
        src_offset := ((y0 + y) * image.width + x0) * image.channels
        dst_offset := y * w * image.channels
        copy(sub[dst_offset:dst_offset + w*image.channels], image.data[src_offset:src_offset + w*image.channels])
    }
    sub_image : ^types.Image = new(types.Image);
    sub_image.data     = sub
    sub_image.width    = w
    sub_image.height   = h
    sub_image.mipmaps  = image.mipmaps
    sub_image.channels = image.channels
    return sub_image
}

load :: proc(file_path: string) -> (^types.Image, bool) {
    width, height, channels : i32;
    c := strings.clone_to_cstring(file_path)
    defer delete(c) // allocates, so free it
    
    data : [^]u8 = image.load(c, &width, &height, &channels, 4)
    defer image.image_free(data)

    size := width*height*channels

    image := new(types.Image)
    image.data = make([]u8, size)
    copy(image.data[0:size],data[0:size])
    image.width = width
    image.height = height
    image.channels = channels
    image.mipmaps = 1

    return image, true
}

free_image :: proc (image: ^types.Image) {
    delete(image.data)
    free(image)
}
