package main;

import "core:fmt"
import b2 "vendor:box2d"
import "../src/core"
import "../src/ecs"
import "../src/ecs/types"
import sc "../src/scripting"
import rn "../src/renderer"
import "../src/io"
import es "../src/event-system"
import sys "../src/ecs/systems"

PIXELS_PER_METER :: 50.0

main :: proc() {

    game := core.init_game();
    defer core.free_game(game);

    roof, _ := sc.new_gameobject(&game.ecs);
    defer free(roof)
    sc.add_component(roof, types.RectangleRenderable({color=rn.get_color(0x00aa00ff)}))
    sc.add_component(roof, types.RigidBody({}))
    roof.transform.pos = {0,200}
    roof.transform.size = {1000,100}
    roof.transform.rot = 5
    sc.add_component(roof, types.SquareCollider({}))

    box, _ := sc.new_gameobject(&game.ecs);
    defer free(box)
    sc.add_component(box, types.RigidBody({type=types.BodyType.dynamicBody}))
    sc.add_component(box, types.SquareCollider({}))
    image,_:= io.load("./game/assets/box.png")
    sc.add_component(box, types.SpriteRenderable({image=image, scale=1}))
    box.transform.pos = {200,-100}
    sc.add_component(box, ecs.Script({
        on_update = proc(e: ^ecs.ECS, ent: u32, dt: f32) {
            rigid, _ := ecs.get_component(e, ent, types.RigidBody)
            for event in es.event_queue_poll() {
                #partial switch v in event{
                    case es.Event_Collision_Entered:
                    //sc.apply_force(v.a, {3000,0})
                }
            }

        }
    }))

    
    tool, _ := sc.new_gameobject(&game.ecs);
    tool.transform.local_pos = {100,0}
    sc.add_component(tool, types.SquareCollider({disabled=true,size={-20,-20}, trigger=true}))


    go, _ := sc.new_gameobject(&game.ecs);
    defer free(go)
    go.transform.size = {100,100}
    sc.add_component(go, types.SquareCollider({size={-20,0}}))
    sc.add_component(go, types.Camera2D({zoom=1}))

  

    ts := io.new_tilesheet("./game/assets/Idle (78x58).png", {64,58}, {14,0})
    defer io.free_tilesheet(ts);
    attack_ts := io.new_tilesheet("./game/assets/Attack (78x58).png", {64,58}, {14,0})
    defer io.free_tilesheet(attack_ts);
    run_ts := io.new_tilesheet("./game/assets/Run (78x58).png", {64,58},{14,0})
    defer io.free_tilesheet(run_ts);


    io.merge_tilesheet(ts, attack_ts);
    io.merge_tilesheet(ts, run_ts);

    parent_rigid, _ := sc.add_component(go, types.RigidBody({
        type=types.BodyType.dynamicBody,
        disable_rotation=true
    }))
    sc.add_component(go, ecs.Script({
        on_update = proc(e: ^ecs.ECS, ent: u32, dt: f32) {
            rigid,_ := ecs.get_component(e,ent, types.RigidBody);
            trans,_ := ecs.get_component(e,ent, types.Transform);
            animator,_ := ecs.get_component(e,ent, types.SpriteAnimator);

            colliders := sc.get_child_components(e, ent, types.SquareCollider);
            
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
            if sc.is_key_pressed(types.KeyboardKey.SPACE) {                
                sc.apply_force(rigid, {0,-3000});
            }
            if sc.is_key_pressed(types.KeyboardKey.ENTER) {
                animator.active_animation = 1
                rigid, _ := ecs.get_component(e, 2, types.RigidBody)
                //sc.apply_force(rigid, {5000,0}) 
                colliders[0].disabled = !colliders[0].disabled
            }

            for event in es.event_queue_poll() {
                #partial switch v in event{
                    case es.Event_SpriteAnimator_End:
                    if v.animator.active_animation != 0  do v.animator.active_animation = 0
                }
            }

        }
    }))
    sprite, _:= sc.add_component(go, types.SpriteRenderable({image=nil, scale=2}))
    sc.add_component(go, types.SpriteAnimator({
        sprite_comp = sprite,
        sprites = ts.images,
        active_animation=0,
        time = 0.1,
        
    }))


    sc.add_child(go,tool)

    core.main_loop(game)
}

