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
    

    
    roof, _ := sc.new_renderobject(&game.ecs);
    defer free(roof)
    sc.add_component(roof, types.RigidBody({}))
    roof.transform.pos = {0,200}
    roof.transform.size = {1000,100}

    box, _ := sc.new_gameobject(&game.ecs);
    defer free(box)
    sc.add_component(box, types.RigidBody({type=types.BodyType.dynamicBody}))
    image,_:= io.load("./game/assets/box.png")
    sc.add_component(box, types.SpriteRenderable({image=image, scale=1}))
    box.transform.pos = {200,-100}
    

    go, _ := sc.new_gameobject(&game.ecs);
    defer free(go)
    go.transform.size = {100,100}
    sc.add_component(go, types.Camera2D({zoom=1}))

    idle_image, loaded := io.load("./game/assets/Idle (78x58).png")
    defer io.free_image(idle_image);
    attack_image, _ := io.load("./game/assets/Attack (78x58).png")
    defer io.free_image(attack_image);
    run_image, _ := io.load("./game/assets/Run (78x58).png")
    defer io.free_image(run_image);
    
    ts := io.new_tilesheet(idle_image, {64,58}, {14,0})
    defer io.free_tilesheet(ts);
    attack_ts := io.new_tilesheet(attack_image, {64,58}, {14,0})
    defer io.free_tilesheet(attack_ts);
    run_ts := io.new_tilesheet(run_image, {64,58},{14,0})
    defer io.free_tilesheet(run_ts);

    io.merge_tilesheet(ts, attack_ts);
    io.merge_tilesheet(ts, run_ts);

    sc.add_component(go, types.RigidBody({
        type=types.BodyType.dynamicBody,
        disable_rotation=true
    }))
    sc.add_component(go, ecs.Script({
        on_update = proc(e: ^ecs.ECS, ent: u32, dt: f32) {
            rigid,_ := ecs.get_component(e,ent, types.RigidBody);
            animator,_ := ecs.get_component(e,ent, types.SpriteAnimator);
            if sc.is_key_down(types.KeyboardKey.A) {
                sc.apply_force(rigid, {-100,0});
                animator.active_animation = 2
                animator.sprite_comp.inverted = true
            } 
            if sc.is_key_down(types.KeyboardKey.D) {
                sc.apply_force(rigid, {100,0});
                animator.active_animation = 2
                animator.sprite_comp.inverted = false
            }
            if sc.is_key_pressed(types.KeyboardKey.SPACE) do sc.apply_force(rigid, {0,-5000});
            if sc.is_key_pressed(types.KeyboardKey.ENTER) do animator.active_animation = 1

            for event in es.event_queue_poll() {
                #partial switch v in event{
                    case es.Event_SpriteAnimator_End:
                    if v.animator.active_animation != 0  do v.animator.active_animation = 0
                }
            }

        }
    }))
    sprite, _:= sc.add_component(go, types.SpriteRenderable({image=idle_image, scale=2}))
    sc.add_component(go, types.SpriteAnimator({
        sprite_comp = sprite,
        sprites = ts.images,
        active_animation=0,
        time = 0.1,
        
    }))


    core.main_loop(game)
}

