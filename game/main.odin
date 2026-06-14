package main;

import "core:fmt"
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

    if ok {

        sc.add_component(go, ecs.SpriteRenderable({"/home/spy/Pictures/davve.png"}))
       
        sc.add_component(go, ecs.PhysicsBody({{0,0},{0,98}}))
        sc.add_component(go, ecs.Script({
            on_update = proc(ecs: ^ecs.ECS, entity: u32, dt:f32) {
                go, _ := sc.get_gameobject(ecs, entity)
                go.transform.pos.x += 100*dt;
            }
        }))
    }
    
    core.main_loop(game);
}

