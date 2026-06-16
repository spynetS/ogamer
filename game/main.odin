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
    go.transform.size = {200,200}

    image, loaded := io.load("./game/assets/Idle (78x58).png")
    defer io.free_image(image);

    ts := io.new_tilesheet(image, {78,58})
    defer io.free_tilesheet(ts);

    image2, _ := io.load("./game/assets/Attack (78x58).png")
    defer io.free_image(image2);

    ts2 := io.new_tilesheet(image2, {78,58})
    defer io.free_tilesheet(ts2);

    io.merge_tilesheet(ts, ts2);

    sc.add_component(go, types.RigidBody({
        type=types.BodyType.dynamicBody,
        disable_gravity = true,
        linear_damping=5
    }))
    sc.add_component(go, ecs.Script({
        on_update = proc(e: ^ecs.ECS, ent: u32, dt: f32) {
            rigid,_ := ecs.get_component(e,ent, types.RigidBody);
            animator,_ := ecs.get_component(e,ent, types.SpriteAnimator);
            if sc.is_key_down(types.KeyboardKey.A) do sc.apply_force(rigid, {-500,0});
            if sc.is_key_down(types.KeyboardKey.D) do sc.apply_force(rigid, {500,0});
            if sc.is_key_down(types.KeyboardKey.SPACE) do animator.active_animation = 1

            for event in es.events {
                #partial switch v in event{
                    case es.Event_SpriteAnimator_End:
                    if v.animator.active_animation == 1 do v.animator.active_animation = 0
                }
            }

        }
    }))
    sprite, _:= sc.add_component(go, types.SpriteRenderable({image=image}))
    sc.add_component(go, types.SpriteAnimator({
        sprite_comp = sprite,
        sprites = ts.images,
        active_animation=0,
        time = 0.5/3,
        
    }))


    core.main_loop(game)
}

