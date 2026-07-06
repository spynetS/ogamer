package main;

import "../src/core"
import "../src/types"
import "../src/io"
import sc "../src/scripting"


game : ^core.Game;

main :: proc() {

    game = core.init_game();
    defer core.free_game(game);

    background,_ := sc.new_gameobject(&game.ecs)
    background.transform.size = {2200,2000}
    background_image,_ := io.load("./game/assets/background0.png")
    sc.add_component(background, types.SpriteRenderable({image=background_image, parallax = {-0.1,-0.2}}))

    create_player(&game.ecs);
    create_enemy(&game.ecs, {160,100});
    create_enemy(&game.ecs, {200,100});

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

    
    floor,_ := sc.new_renderobject(&game.ecs);
    floor.transform.pos = {0,-400}
    floor.transform.size = {700,200}
    sc.add_component(floor, types.RigidBody({}))
    sc.add_component(floor, types.SquareCollider({}))

    sc.add_component(floor, types.TileMap({
        width=10,
        height=2,
        tiles=floor_tiles
    }))





    core.main_loop(game);
}

