package main;
import "../src/ecs"
import "../src/types"
import "../src/io"
import sc "../src/scripting"
   

create_floor :: proc (ecs: ^types.ECS, pos, size : types.Vector2) {
    tilesheet := io.new_tilesheet("./game/assets/Terrain (32x32).png", {32,32})

    floor_tiles := make([dynamic]^types.Image)
    append(&floor_tiles, tilesheet.images[5][1])
    for i in 0..<8 {
        append(&floor_tiles, tilesheet.images[5][2])
    }
    append(&floor_tiles, tilesheet.images[5][3])
    append(&floor_tiles, tilesheet.images[5][1])
    for i in 0..<8 {
        append(&floor_tiles, tilesheet.images[5][2])
    }
    append(&floor_tiles, tilesheet.images[5][3])

    
    floor,_ := sc.new_gameobject(ecs);
    floor.transform.pos = pos
    floor.transform.size = size
    sc.add_component(floor, types.RigidBody({}))
    sc.add_component(floor, types.SquareCollider({}))

    sc.add_component(floor, types.TileMap({
        width=10,
        height=2,
        tiles=floor_tiles
    }))

}
