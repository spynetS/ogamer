package core;
import "core:fmt"
import "../scripting"
import "../types"
import "../io"

create_sprites :: proc(_map: ^Map) {
    
}

get_tileset :: proc(_map: ^Map, gid: int) -> (TileSet, bool) {
    if gid == 0 do return {}, false  // 0 = empty cell in Tiled

    result: TileSet
    found := false
    for tileset in _map.tilesets {
        if tileset.firstgid <= gid && (!found || tileset.firstgid > result.firstgid) {
            result = tileset
            found = true
        }
    }
    return result, found
}

create_from_map :: proc (ecs: ^types.ECS, _map: ^Map) {
    //tilesheet := io.new_tilesheet("../../Downloads/Legacy-Fantasy - High Forest 2.3/Assets/Tiles.png", {16,16})
    for layer in _map.layers {        
        for i in 0..<len(layer.data) {
            value := layer.data[i] & 0x0FFF_FFFF  // clear h/v/diagonal/rotate flags
            if tileSet, found := get_tileset(_map, value); found {
                grid_x := (value - tileSet.firstgid) % (tileSet.columns);
                grid_y := (value - tileSet.firstgid) / (tileSet.columns);

                x := i % (layer.width)
                y := i / (layer.width)

                go,_ := scripting.new_gameobject(ecs)
                defer free(go)
                go.transform.size = {cast(f32)tileSet.tilewidth, cast(f32)tileSet.tileheight}
                go.transform.pos.x =   cast(f32)(x-layer.width/2)  * cast(f32)_map.tilewidth;
                go.transform.pos.y = - cast(f32)(y-layer.height/2) * cast(f32)_map.tileheight;
                fmt.println("WHAT:",grid_x,grid_y, tileSet.tilewidth)
                scripting.add_component(go, types.SpriteRenderable({image=tileSet.tilesheet.images[grid_y][grid_x]}))
            }
        }
    }
}

