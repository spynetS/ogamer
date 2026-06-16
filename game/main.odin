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

    sc.add_component(go, types.RigidBody({type=types.BodyType.dynamicBody}))
    sc.add_component(go, ecs.Script({
        on_update = proc(e: ^ecs.ECS, ent: u32, dt: f32) {
            rigid,_ := ecs.get_component(e,ent, types.RigidBody);
            if sc.is_key_down(types.KeyboardKey.A) do sc.apply_force(rigid, {-500,0});
            if sc.is_key_down(types.KeyboardKey.D) do sc.apply_force(rigid, {500,0});
        }
    }))
    sprite, _:= sc.add_component(go, types.SpriteRenderable({image=image}))
    sc.add_component(go, types.SpriteAnimator({
        sprite_comp = sprite,
        sprites = ts.images[0],
        time = 0.05,
        
    }))


    core.main_loop(game)
}

