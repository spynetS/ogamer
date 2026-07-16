package ogamer_io;

import "vendor:stb/image"
import "core:strings"

import "core:mem/virtual"

load :: proc(handler: ^AssetsManager, file_path: string, uv: UV = {{0,0},{1,1}}) -> (Sprite, bool) #optional_ok {
    texture, ok := load_path(handler, file_path)
    if !ok do return Sprite({}), false
    
    texture_id := Texture_ID(file_path)
    handler.textures[texture_id] = texture

    return Sprite({
        texture = texture_id,
        uv = uv
    }), true
    
}

load_path :: proc(handler: ^AssetsManager, file_path: string) -> (^Image, bool) #optional_ok {
    width, height, channels : i32;
    c := strings.clone_to_cstring(file_path)
    defer delete(c) // allocates, so free it
    
    data : [^]u8 = image.load(c, &width, &height, &channels, 4)
    defer image.image_free(data)

    size := width*height*channels

    image := new(Image, allocator=virtual.arena_allocator(&handler.arena))
    image.data = make([]u8, size, allocator=virtual.arena_allocator(&handler.arena))
    copy(image.data[0:size],data[0:size])
    image.width = width
    image.height = height
    image.channels = channels
    image.mipmaps = 1

    return image, true
}

destroy_handler :: proc(handler: ^AssetsManager) {
    virtual.arena_destroy(&handler.arena)
    delete(handler.textures)
    free(handler)
}

