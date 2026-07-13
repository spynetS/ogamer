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
    game = core.init_game();
    defer core.free_game(game);

    _map := core.load_map("./game2/map.tmj")
    core.create_from_map(
            &game.ecs,
        _map,
        {3,3},
        on_create = proc (obj: core.Object, transform: types.Transform){
            if obj.class == "player" do create_player(&game.ecs, transform.pos)
            if obj.class == "enemy" do create_enemy(&game.ecs, transform.pos)

        })

    core.destroy(_map)
    core.main_loop(game)
}

