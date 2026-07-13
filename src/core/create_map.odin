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

create_from_map :: proc (ecs: ^types.ECS, _map: ^Map, tile_scale: types.Vector2 = {1,1}) {
    for layer in _map.layers {
        if layer.visible == 0 do continue
        fmt.println("LAYER:", layer)
        for i in 0..<len(layer.data) {
            value := layer.data[i] & 0x0FFF_FFFF  // clear h/v/diagonal/rotate flags
            if tileSet, found := get_tileset(_map, value); found {
                grid_x := (value - tileSet.firstgid) % tileSet.columns
                grid_y := (value - tileSet.firstgid) / tileSet.columns

                x := i % layer.width
                y := i / layer.width

                tw  := cast(f32)tileSet.tilewidth   // tile size (may be > grid cell)
                th  := cast(f32)tileSet.tileheight
                
                mtw := cast(f32)_map.tilewidth      // grid cell size
                mth := cast(f32)_map.tileheight

                // scaling
                tw  *= tile_scale.x
                th  *= tile_scale.y
                mtw *= tile_scale.x
                mth *= tile_scale.y

                fx := cast(f32)x;  fy := cast(f32)y
                fw := cast(f32)layer.width;  fh := cast(f32)layer.height

                go, _ := scripting.new_gameobject(ecs)
                go.transform.size = {tw, th}

                // Tiled = bottom-left cell anchor, Y-down. Ours = center anchor, Y-up.
                go.transform.pos.x = fx*mtw - fw*mtw/2 + tw/2
                go.transform.pos.y = fh*mth/2 - (fy+1)*mth + th/2

                scripting.add_component(go, types.SpriteRenderable({
                    image = tileSet.tilesheet.images[grid_y][grid_x],
                    parallax=layer.parallax
                }))

            }
        }
    }
}

