package main;
import "../src/ecs"
import "../src/types"
import "../src/io"
import sc "../src/scripting"
   

create_floor :: proc (ecs: ^types.ECS, pos, size : types.Vector2) {
    tilesheet := io.new_tilesheet("./game/assets/FREE_Fantasy Forest/Tiles/Tileset Outside.png", {32,32})

    floor_tiles := make([dynamic]^types.Image)


    append(&floor_tiles, tilesheet.images[0][0])
    for j in 0..<(size.x)/100-2  {
        append(&floor_tiles, tilesheet.images[0][1])
    }
    append(&floor_tiles, tilesheet.images[0][2])

    
    for i in 1..<(size.y)/100-1  {
        append(&floor_tiles, tilesheet.images[1][0])
        for j in 0..<(size.x)/100-2  {
            append(&floor_tiles, tilesheet.images[1][1])
        }
        append(&floor_tiles, tilesheet.images[1][2])
    }

    append(&floor_tiles, tilesheet.images[2][0])
    for j in 0..<(size.x)/100-2  {
        append(&floor_tiles, tilesheet.images[2][1])
    }
    append(&floor_tiles, tilesheet.images[2][2])


    
    floor,_ := sc.new_gameobject(ecs);
    floor.transform.pos = pos
    floor.transform.size = size
    sc.add_component(floor, types.RigidBody({}))
    sc.add_component(floor, types.SquareCollider({}))

    sc.add_component(floor, types.TileMap({
        width=int(floor.transform.size.x)/100,
        height=int(floor.transform.size.y)/100,
        tiles=floor_tiles
    }))

}
