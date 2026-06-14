package file_io;

import "vendor:stb/image"
import "core:strings"

Image :: struct {
    data : [^]u8,
    width, height, mipmaps : i32
}

IOHandler :: struct {
    images : map[string]^Image
}

add :: proc(handler : ^IOHandler, file_path: string) -> (^Image, bool){
    image, ok := load(file_path)
    if ok do handler.images[file_path] = image
    return image, true
}

get :: proc(handler : ^IOHandler, file_path: string) -> (^Image, bool){
    if handler == nil do return nil, false
    image, ok := handler.images[file_path]
    if !ok {
        return load(file_path)
    }
    return image, ok
}

load :: proc(file_path: string) -> (^Image, bool) {
    width, height, channels : i32;
    c := strings.clone_to_cstring(file_path)
    defer delete(c) // allocates, so free it
    data : [^]u8 = image.load(c, &width, &height, &channels, 4)
    image := new(Image)
    image.data = data
    image.width = width
    image.height = height
    image.mipmaps = 1

    return image, true
}

