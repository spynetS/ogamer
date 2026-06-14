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

    go, ok := sc.new_gameobject(&game.ecs)
    defer free(go);
    
    if ok {
        sc.add_component(go, ec.RectangleRenderable({rn.get_color(0x181818ff)}))
        sc.add_component(go, ec.PhysicsBody({{0,0},{0,98}}))
        sc.add_component(go, ecs.Script({
            on_update = proc(ecs: ^ecs.ECS, entity: ec.Entity, dt:f32) {
                go, _ := sc.get_gameobject(ecs, entity)
                go.transform.pos.x += 1;
            }
        }))
    }
    
    core.main_loop(game);
}

