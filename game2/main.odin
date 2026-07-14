package game2;

import "../src/core"
import "../src/types"
import "../src/io"
import "../src/ecs"
import sc "../src/scripting"
import rn "../src/renderer"
import "core:fmt"

game: ^core.Game

create_player :: proc(pos: types.Vector2) {
    go := sc.new_gameobject(&game.ecs);
    defer sc.free_gameobject(go)
    go.transform.pos = pos
    tilesheet := io.new_tilesheet(game.io_handler, "./game/assets/Attack (78x58).png", {78,58})
    sc.add_component(go, types.SpriteAnimator({
        sprites=tilesheet.sprites,
        time=0.1
    }))
    free(tilesheet)
    sc.add_component(go, types.Camera2D({zoom=1}))
    rigid := sc.add_component(go, types.RigidBody({type=types.BodyType.dynamicBody, disable_rotation=true}))
    sc.add_component(go, types.SquareCollider({}))

    sc.add_component(go, types.Script({
        data = rigid, 
        on_update = proc(go: types.GameObject, data: rawptr, dt:f32) {
            rigid := cast(^types.RigidBody)data
            if sc.is_key_down(types.KeyboardKey.A) do sc.apply_force(rigid, -{5000,0}*dt)
            if sc.is_key_down(types.KeyboardKey.D) do sc.apply_force(rigid, {5000,0}*dt)
            if sc.is_key_pressed(types.KeyboardKey.SPACE) do sc.apply_force(rigid, {0,80000}*dt)
        }
    }))

}

main :: proc() {
    game = core.init_game();
    _map := core.load_map(game.io_handler, "./game2/map/map.tmj")

    defer core.destroy(_map)
    defer core.free_game(game);


    core.create_from_map(
        game,
        _map,
        {1.5,1.5},
        on_create = proc (obj: core.Object, transform: types.Transform){
            if obj.class == "player" do create_player(transform.pos)
        })


    core.main_loop(game)
}

