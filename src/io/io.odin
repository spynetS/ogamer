package file_io;

import "vendor:stb/image"
import "core:strings"

import "../types"
import "core:mem/virtual"

// get :: proc(handler : ^types.IOHandler, file_id: types.Sprite) -> (^types.Image, bool) #optional_ok{
//     if handler == nil do return nil, false
//     image, ok := handler.images[file_id]
//     if !ok {
//         image = load_path(file_id)
//         handler.images[file_id] = image
//         return image, true
//     }
//     return image, ok
// }
load :: proc(handler: ^types.IOHandler, file_path: string, uv: types.UV = {{0,0},{1,1}}) -> (types.Sprite, bool) #optional_ok {
    texture, ok := load_path(handler, file_path)
    if !ok do return types.Sprite({}), false
    
    texture_id := types.Texture_ID(file_path)
    handler.textures[texture_id] = texture

    return types.Sprite({
        texture = texture_id,
        uv = uv
    }), true
    
}

load_path :: proc(handler: ^types.IOHandler, file_path: string) -> (^types.Image, bool) #optional_ok {
    width, height, channels : i32;
    c := strings.clone_to_cstring(file_path)
    defer delete(c) // allocates, so free it
    
    data : [^]u8 = image.load(c, &width, &height, &channels, 4)
    defer image.image_free(data)

    size := width*height*channels

    image := new(types.Image, allocator=virtual.arena_allocator(&handler.arena))
    image.data = make([]u8, size, allocator=virtual.arena_allocator(&handler.arena))
    copy(image.data[0:size],data[0:size])
    image.width = width
    image.height = height
    image.channels = channels
    image.mipmaps = 1

    return image, true
}

free_handler :: proc(handler: ^types.IOHandler) {
    virtual.arena_destroy(&handler.arena)
    delete(handler.textures)
    free(handler)
}

