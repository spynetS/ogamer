package main;

import "../src/core"
import "../src/ecs"
import "../src/ecs/types"
import sc "../src/scripting"
import rn "../src/renderer"



main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);

    camera, _ := sc.new_gameobject(&game.ecs);
    sc.add_component(camera, types.Camera2D({{0,0},{0,0},0,1}))

    child, _ := sc.new_gameobject(&game.ecs);
    sc.add_component(child, types.RectangleRenderable({rn.get_color(0xaaaaffff)}))
    child.transform.local_pos = {100,0}
      
    go, ok := sc.new_gameobject(&game.ecs)
    defer free(go);
    go.transform.size = {200,200}
    sc.add_component(go, types.SpriteRenderable({"./game/assets/token.png"}))

    sc.add_component(go, ecs.Script({
        on_update = proc(ecs_: ^ecs.ECS, entity: u32, dt:f32) {
            go, _ := sc.get_gameobject(ecs_, entity)
            go.transform.pos.x += 100*dt;
            go.transform.rot += 1
        }
    }))
    sc.add_child(go,child)
    
    core.main_loop(game);
}

