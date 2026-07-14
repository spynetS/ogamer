package core;
import "core:fmt"
import "../scripting"
import "../renderer"
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

create_objectgroup :: proc(ecs: ^types.ECS, _map: ^Map, tile_scale: types.Vector2 = {1,1}, on_create: proc(Object, types.Transform) = nil) {
    // map height in pixels, scaled — used only for the Y flip
    map_w := cast(f32)_map.width * cast(f32)_map.tilewidth * tile_scale.x
    map_h := cast(f32)_map.height * cast(f32)_map.tileheight * tile_scale.y

    for objectgroup in _map.objectgroups {
        for object in objectgroup.objects {
            if !object.visible do continue
            is_tile := object.gid != -1
            // FIXME maybe not create a entity if not necceary
            go := scripting.new_gameobject(ecs)
            defer scripting.free_gameobject(go)
            
            x := object.x * tile_scale.x
            y := object.y * tile_scale.y

            go.transform.size = {object.width, object.height}*tile_scale
            go.transform.pos = {x-map_w/2, -y+map_h/2}

            
            if is_tile do go.transform.pos += {object.width/2, object.height/2}*tile_scale
            else       do go.transform.pos += {object.width/2, -object.height/2}*tile_scale

            if is_tile {
                gid := object.gid & 0x0FFF_FFFF   // strip flip/rotate flags
                if tileset, found := get_tileset(_map, gid); found {
                    grid_x := (gid - tileset.firstgid) % tileset.columns
                    grid_y := (gid - tileset.firstgid) / tileset.columns
                    scripting.add_component(go, types.SpriteRenderable({
                        layer=objectgroup.layer_depth,
                        image = tileset.tilesheet.images[grid_y][grid_x],
                    }))
                }
            }
            if object.class == "collider" {
                scripting.add_component(go, types.RigidBody({}))
                scripting.add_component(go, types.SquareCollider({}))
            }
            on_create(object, go.transform^)
        }
    }
}

position_gameobject :: proc (
    go: ^types.GameObject,
    map_pos:types.Vector2,
    size: types.Vector2,
    tileset: TileSet,
    _map: ^Map,
    tile_scale: types.Vector2 = {1,1}) {
    
                tw  := cast(f32)tileset.tilewidth // tile size (may be > grid cell)
                th  := cast(f32)tileset.tileheight
                
                mtw := cast(f32)_map.tilewidth      // grid cell size
                mth := cast(f32)_map.tileheight

                // scaling
                tw  *= tile_scale.x
                th  *= tile_scale.y
                mtw *= tile_scale.x
                mth *= tile_scale.y

                fx := cast(f32)map_pos.x;  fy := cast(f32)map_pos.y
                fw := cast(f32)size.x;  fh := cast(f32)size.y

                go.transform.size = {tw, th}

                // Tiled = bottom-left cell anchor, Y-down. Ours = center anchor, Y-up.
                go.transform.pos.x = fx*mtw - fw*mtw/2 + tw/2
                go.transform.pos.y = fh*mth/2 - (fy+1)*mth + th/2
}

create_tiles :: proc (ecs: ^types.ECS, _map: ^Map, tile_scale: types.Vector2 = {1,1}) {
    for layer in _map.layers {
        if layer.visible == false do continue
        fmt.println("LAYER:", layer)
        for i in 0..<len(layer.data) {
            value := layer.data[i] & 0x0FFF_FFFF  // clear h/v/diagonal/rotate flags
            if tileSet, found := get_tileset(_map, value); found {
                if tileSet.columns == 0 do continue
                grid_x := (value - tileSet.firstgid) % tileSet.columns
                grid_y := (value - tileSet.firstgid) / tileSet.columns

                x := i % layer.width
                y := i / layer.width
                
                go := scripting.new_gameobject(ecs)
                defer scripting.free_gameobject(go)
                
                position_gameobject(go,
                                    {cast(f32)x,cast(f32)y},
                                    {cast(f32)layer.width,cast(f32)layer.height},
                                    tileSet,
                                    _map,
                                    tile_scale)

                scripting.add_component(go, types.SpriteRenderable({
                    image = tileSet.tilesheet.images[grid_y][grid_x],
                    layer=layer.layer_depth,
                    parallax=layer.parallax-1
                }))

             }
        }
    }
}



create_imagelayer :: proc(ecs: ^types.ECS, _map: ^Map, tile_scale: types.Vector2 = {1,1}) {
    map_w := cast(f32)_map.width * cast(f32)_map.tilewidth * tile_scale.x
    map_h := cast(f32)_map.height * cast(f32)_map.tileheight * tile_scale.y
    for imagelayer in _map.imagelayers {
        if !imagelayer.visible do continue
        // TODO implement repeat
        go := scripting.new_gameobject(ecs)
        defer scripting.free_gameobject(go)

        x := imagelayer.offsetx * tile_scale.x
        y := -imagelayer.offsety * tile_scale.y

        go.transform.pos = {
            x-map_w/2,
            y-map_h/2
        } 
        go.transform.size = {
            cast(f32)imagelayer.imagewidth,
            cast(f32)imagelayer.imageheight
        } * tile_scale

        go.transform.pos += {imagelayer.imagewidth/2, imagelayer.imageheight/2}*tile_scale
        // memory leak
        image, loaded := io.load(imagelayer.image)
 
        scripting.add_component(go, types.SpriteRenderable({
            image=image,
            layer=imagelayer.layer_depth,
            parallax = imagelayer.parallax-1,
            repeated_x = imagelayer.repeatx,
            repeated_y = imagelayer.repeaty
        }))
    }
}

create_from_map :: proc (ecs: ^types.ECS, _map: ^Map, tile_scale: types.Vector2 = {1,1}, on_create: proc(Object, types.Transform) = nil) {

    create_tiles(ecs, _map, tile_scale)
    create_objectgroup(ecs, _map, tile_scale, on_create)
    create_imagelayer(ecs,_map, tile_scale)
}

