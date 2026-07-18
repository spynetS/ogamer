package ogamer_tiled;
import "core:fmt"
import "core:mem/virtual"
import "../renderer"
import "../io"
import "../ecs"
import og "../"

Vector2 :: [2]f32

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

create_objectgroup :: proc(game: ^og.Game, _map: ^Map, tile_scale: Vector2 = {1,1}, on_create: proc(Object, ecs.Transform) = nil) {
    // map height in pixels, scaled — used only for the Y flip
    map_w := cast(f32)_map.width * cast(f32)_map.tilewidth * tile_scale.x
    map_h := cast(f32)_map.height * cast(f32)_map.tileheight * tile_scale.y
    
    fmt.println(_map.objectgroups)
    for objectgroup in _map.objectgroups {
        fmt.println(objectgroup)
        for object in objectgroup.objects {
            if !object.visible do continue
            is_tile := object.gid != -1
            // FIXME maybe not create a entity if not necceary
            go :=  og.new_gameobject(game.ecs)
            
            x := object.x * tile_scale.x
            y := object.y * tile_scale.y

            go.transform.size = {object.width, object.height}*tile_scale
            go.transform.pos = {x-map_w/2, -y+map_h/2}

            
            if is_tile do go.transform.pos += {object.width/2, object.height/2}*tile_scale
            else       do go.transform.pos += {object.width/2, -object.height/2}*tile_scale

            if is_tile {
                gid := object.gid & 0x0FFF_FFFF   // strip flip/rotate flags
                if tileset, found := get_tileset(_map, gid); found {
                    add_sprite(game, &go, objectgroup.layer_depth, objectgroup.parallax, tileset, gid)
                }
            }
            if object.class == "collider" {
                assert(false)
                // og.add_component(go, types.RigidBody({}))
                // og.add_component(go, types.SquareCollider({}))
                // fmt.println("COLLIDER")
            }
            if on_create != nil do on_create(object, go.transform^)
        }
    }
}

add_sprite :: proc(game: ^og.Game, go: ^og.GameObject, layer_depth: int, parallax: Vector2, tileSet: TileSet, value: int) {
    grid_x := (value - tileSet.firstgid) % tileSet.columns
    grid_y := (value - tileSet.firstgid) / tileSet.columns

    // if the tileset has a specgic tile we can we have to do some more stuff
    if tile, found := tileSet.tiles[value-tileSet.firstgid]; found {
        fmt.println("FOUND ANIMATION")
        switch tile in tile{
        case Animation:
            size := len(tile.frames)
            sprites := make([][]io.Sprite, 1, allocator=virtual.arena_allocator(&game.assetsManager.arena))
            sprites[0] = make([]io.Sprite, size, allocator=virtual.arena_allocator(&game.assetsManager.arena))
            for i in 0..<size {
                gid := tile.frames[i].tileid
                grid_x := (gid) % tileSet.columns
                grid_y := (gid) / tileSet.columns
                sprite := tileSet.tilesheet.sprites[grid_y][grid_x]
                sprites[0][i] = sprite
            }
            og.add_component(go^, ecs.SpriteAnimator({
                sprites=sprites,
                time=10/cast(f32)tile.frames[0].duration,
            }))
        }

    }
    else {
        og.add_component(go^, ecs.SpriteRenderer({
            sprite = tileSet.tilesheet.sprites[grid_y][grid_x],
            layer=layer_depth,
            parallax=parallax-1
        }))
    }
}

position_gameobject :: proc (
    go: og.GameObject,
    map_pos:Vector2,
    size: Vector2,
    tileset: TileSet,
    _map: ^Map,
    tile_scale: Vector2 = {1,1})
{
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

// TODO make so instead of creating a bunch of entities create 1 entity with multiple sprites
// maybe add a new component that can render muliple sprites (TileMap component)
create_tiles :: proc (game: ^og.Game, _map: ^Map, tile_scale: Vector2 = {1,1}) {
    for layer in _map.layers {
        if layer.visible == false do continue
        fmt.println("LAYER:", layer)
        for i in 0..<len(layer.data) {
            value := layer.data[i] & 0x0FFF_FFFF  // clear h/v/diagonal/rotate flags
            if tileSet, found := get_tileset(_map, value); found {
                if tileSet.columns == 0 do continue

                x := i % layer.width
                y := i / layer.width
                
                go := og.new_gameobject(game.ecs)
                
                position_gameobject(go,
                                    {cast(f32)x,cast(f32)y},
                                    {cast(f32)layer.width,cast(f32)layer.height},
                                    tileSet,
                                    _map,
                                    tile_scale)
                add_sprite(game, &go, layer.layer_depth, layer.parallax, tileSet, value)
            }
        }
    }
}



create_imagelayer :: proc(game: ^og.Game, _map: ^Map, tile_scale: Vector2 = {1,1}) {
    map_w := cast(f32)_map.width * cast(f32)_map.tilewidth * tile_scale.y
    map_h := cast(f32)_map.height * cast(f32)_map.tileheight * tile_scale.y
    for imagelayer in _map.imagelayers {
        if !imagelayer.visible do continue

        go := og.new_gameobject(game.ecs)

        x := imagelayer.offsetx * tile_scale.x
        y := imagelayer.offsety * tile_scale.y


        

        fmt.println(imagelayer.imagewidth, imagelayer.imageheight)
        fmt.println(_map.width, _map.height)


        go.transform.size = {
            cast(f32)imagelayer.imagewidth,
            cast(f32)imagelayer.imageheight
        } * tile_scale


        go.transform.pos += go.transform.size/2 * {1,-1} // we translate so top corner is middle
        go.transform.pos += {-20*f32(_map.tilewidth), 20*f32(_map.tileheight)}/2 * tile_scale // translate so top corner is
        go.transform.pos += {x,-y} // translate the offset params

        sprite, loaded := io.load(game.assetsManager, imagelayer.image)
        
        og.add_component(go, ecs.SpriteRenderer({
            sprite=sprite,
            layer=imagelayer.layer_depth,
            parallax = imagelayer.parallax-1,
            repeated_x = imagelayer.repeatx,
            repeated_y = imagelayer.repeaty
        }))
    }
}

create_from_map :: proc (game: ^og.Game, _map: ^Map, tile_scale: Vector2 = {1,1}, on_create: proc(Object, ecs.Transform) = nil) {
    if _map == nil do return
    create_tiles(game, _map, tile_scale)
    create_objectgroup(game, _map, tile_scale, on_create)
    create_imagelayer(game,_map, tile_scale)
}

