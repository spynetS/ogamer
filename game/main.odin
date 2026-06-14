package main;

import "core:fmt"
import "../src/core"
import "../src/ecs"
import sc "../src/scripting"
import ec "../src/ecs/ecs_core"
import rn "../src/renderer"


main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);

    go, ok := sc.get_gameobject(&game.ecs, 0)
    defer sc.free_gameobject(go);
    
    if ok {
        sc.add_component(go, ec.RectangleRenderable({rn.get_color(0x181818ff)}))
        sc.add_component(go, ec.PhysicsBody({{0,0},{0,980}}))
    }
    
    core.main_loop(game);
}

