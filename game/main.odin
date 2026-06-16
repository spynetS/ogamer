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
    sc.add_component(camera, types.Camera2D({zoom=1}))

    go, _ := sc.new_gameobject(&game.ecs);
    defer free(go)
    image, loaded := io.load("./game/assets/Idle (78x58).png")
    defer io.free_image(image);

    ts := io.new_tilesheet(image, {78,58})
    defer io.free_tilesheet(ts);

    for i in 0..<len(ts.images[0]){
        go, _ = sc.new_gameobject(&game.ecs)
        go.transform.pos = {f32(50*i)-250,0}
        sc.add_component(go, types.SpriteRenderable({image=ts.images[0][i]}))
    }

    core.main_loop(game)
}

