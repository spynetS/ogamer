package game2;

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
    core.create_from_map(&game.ecs,
                         _map,
                         {3,3},
                         on_create = proc (obj: core.Object){
                             if obj.class == "player" do create_player(&game.ecs, {obj.x, obj.y})
                         })

//    create_player(&game.ecs, {-200,0})

    core.destroy(_map)
    core.main_loop(game)
}

