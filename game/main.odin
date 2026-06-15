package main;

import "core:fmt"
import "../src/core"
import "../src/ecs"
import "../src/ecs/types"
import sc "../src/scripting"
import rn "../src/renderer"
import es "../src/event-system"



main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);

    camera, _ := sc.new_gameobject(&game.ecs);
    defer free(camera)
    sc.add_component(camera, types.Camera2D({{0,0},{0,0},0,1}))

    roof, roof_ok := sc.new_gameobject(&game.ecs)
    defer free(roof)
    if roof_ok {
        roof.transform.pos = {50, 300}
        sc.add_component(roof, types.RectangleRenderable({rn.get_color(0xaaaaffff)}))
        rigid := types.RigidBody({})
        rigid.type = types.BodyType.staticBody
        sc.add_component(roof, rigid)
    }

    go, ok := sc.new_gameobject(&game.ecs)
    defer free(go);
    go.transform.size = {200,100}
    sc.add_component(go, types.RectangleRenderable({rn.get_color(0xaaaaffff)}))
    sc.add_component(go, types.Camera2D({{0,0},{0,0},0,1}))
    rigid := types.RigidBody({})
    rigid.type = types.BodyType.dynamicBody
    sc.add_component(go, rigid)

    sc.add_component(go, ecs.Script({
        on_update = proc(ecs_ : ^ecs.ECS, e: u32, dt: f32) {
            rigid, _ := ecs.get_component(ecs_,e, types.RigidBody)
            if sc.is_key_pressed(types.KeyboardKey.SPACE) do sc.apply_force(rigid, {0,-5000})
            if sc.is_key_down(types.KeyboardKey.A) do sc.apply_force(rigid, {-100,0})
            if sc.is_key_down(types.KeyboardKey.D) do sc.apply_force(rigid, {100,0})

        }
    }))


    core.main_loop(game);
}

