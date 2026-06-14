package main;

import "core:fmt"
import rl "vendor:raylib"
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
        go.transform.pos = {500,500}
        //sc.add_component(go, ecs.SpriteRenderable({"./game/assets/token.png"}))
        sc.add_component(go, ecs.RectangleRenderable({rn.get_color(0x181818ff)}))
        sc.add_component(go, ecs.RigidBody({{0,0},{0,98}, ecs.BodyType.dynamicBody}))
        
        sc.add_component(go, ecs.Script({
            on_update = proc(ecs_: ^ecs.ECS, entity: u32, dt: f32) {
                if(rl.IsKeyPressed(rl.KeyboardKey.SPACE)){
                    rigid, _ := ecs.get_component(ecs_, entity, ecs.RigidBody)
                    sc.apply_force(rigid, {0,-6000})
                
                }
                if(rl.IsKeyDown(rl.KeyboardKey.D)){
                    rigid, _ := ecs.get_component(ecs_, entity, ecs.RigidBody)
                    sc.apply_force(rigid, {100,0})
                
                }
                if(rl.IsKeyDown(rl.KeyboardKey.A)){
                    rigid, _ := ecs.get_component(ecs_, entity, ecs.RigidBody)
                    sc.apply_force(rigid, {-100,0})
                
                }
            }
        }))
    }


    go2, ok2 := sc.new_gameobject(&game.ecs)
    defer free(go2);
    if ok2 {
        go2.transform.size = {460,100}
        go2.transform.pos = {460,700}
        //sc.add_component(go2, ecs.SpriteRenderable({"./game/assets/token.png"}))
        sc.add_component(go2, ecs.RectangleRenderable({rn.get_color(0x181818ff)}))
        sc.add_component(go2, ecs.RigidBody({{0,0},{0,98}, ecs.BodyType.staticBody}))

        
    }

    
    core.main_loop(game);
}

