package main;

import "core:fmt"
import "vendor:box2d"
import "../src/core"
import "../src/ecs"
import sc "../src/scripting"
import rn "../src/renderer"
import io "../src/io"



main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);


    go, ok := sc.new_gameobject(&game.ecs)
    defer free(go);

    go.transform.pos = {500,300}


    if ok {

        sc.add_component(go, ecs.SpriteRenderable({"./game/assets/token.png"}))
        sc.add_component(go, ecs.PhysicsBody({{0,0},{0,98}}))





        
        
    }
    
    core.main_loop(game);
}

