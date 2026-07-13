package main;

import "../src/core"
import "../src/types"
import "../src/io"
import "../src/ecs"
import sc "../src/scripting"
import rn "../src/renderer"
import "core:fmt"

game: ^core.Game

main :: proc() {
    //level.load(nil)

    game = core.init_game();
    defer core.free_game(game);

    _map := core.load_map("./game2/map.tmj")

    
    fmt.println("MAP:", _map)
    // go := sc.new_gameobject(&game.ecs);
    // //go.transform.pos.x = -1500/2
    // go.transform.pos.y = 200
    // sc.add_component(go, types.Camera2D({zoom=1}))
    // sc.add_component(go, types.Script({
    //     on_update = proc(go: types.GameObject, data: rawptr, dt:f32) {
    //         if sc.is_key_down(types.KeyboardKey.D) do go.transform.pos += {20,0}
    //         if sc.is_key_down(types.KeyboardKey.A) do go.transform.pos -= {20,0}
    //         if sc.is_key_down(types.KeyboardKey.Q) do game.renderer.active_camera.zoom -= 0.01
    //         if sc.is_key_down(types.KeyboardKey.E) do game.renderer.active_camera.zoom += 0.01

    //     }
    // }))
    core.create_from_map(&game.ecs, _map, {3,3})

    go,_ := sc.new_renderobject(&game.ecs);
    go.transform.pos.x = -200
    camera := sc.new_gameobject(&game.ecs)
    camera.transform.local_pos = {0,200}
    sc.add_component(camera, types.Camera2D({zoom=1}))
    sc.add_child(go,camera)
    rigid,_ := sc.add_component(go, types.RigidBody({type=types.BodyType.dynamicBody, disable_rotation=true}))
    sc.add_component(go, types.SquareCollider({}))
    sc.add_component(go, types.Script({
        data= rigid,
        on_update = proc(go: types.GameObject, data: rawptr, dt:f32) {
            rigid:= cast(^types.RigidBody)data
            if sc.is_key_down(types.KeyboardKey.D) do sc.apply_force(rigid,{100,0})
            if sc.is_key_down(types.KeyboardKey.A) do sc.apply_force(rigid,{-100,0})
            if sc.is_key_pressed(types.KeyboardKey.SPACE) do sc.apply_force(rigid,{0,1000})
        }
    }))
    
    core.destroy(_map)
    core.main_loop(game)
}

