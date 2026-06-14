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

    go.transform.size = {200,200}

    go2, ok2 := sc.new_gameobject(&game.ecs)
    defer free(go2);
    if ok2 {
        go2.transform.local_pos = {100,0}
        sc.add_component(go2, ecs.RectangleRenderable({rn.get_color(0x181818ff)}))
    }

    // go2.transform.local_size = {100,100}
    

    if ok {

        sc.add_component(go, ecs.SpriteRenderable({"./game/assets/token.png"}))
        sc.add_component(go, ecs.PhysicsBody({{0,0},{0,98}}))
        sc.add_component(go, ecs.Script({
            on_update = proc(ecs: ^ecs.ECS, entity: u32, dt:f32) {
                go, _ := sc.get_gameobject(ecs, entity)
                go.transform.pos.x += 100*dt;
            }
        }))

        sc.add_child(go,go2);
    }
    
    core.main_loop(game);
}

