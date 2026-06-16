package main;

import "core:fmt"
import "../src/core"
import "../src/ecs"
import "../src/ecs/types"
import sc "../src/scripting"
import rn "../src/renderer"
import "../src/io"
import es "../src/event-system"



main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);

    camera, _ := sc.new_gameobject(&game.ecs);
    defer free(camera)
    sc.add_component(camera, types.Camera2D({{0,0},{0,0},0,1}))

    go, _ := sc.new_gameobject(&game.ecs);
    defer free(go)
    image, loaded := io.load("./game/assets/Idle (78x58).png")
    defer io.free_image(image);
    croped := io.crop(image, 0,0,78,58);
    defer io.free_image(croped);

    
    if loaded do sc.add_component(go, types.SpriteRenderable({croped}))
    else do sc.add_component(go, types.RectangleRenderable({rn.get_color(0x181818ff)}))

    core.main_loop(game);
}

