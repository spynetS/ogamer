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

    _map := core.load_map(game.io_handler, "./game2/map.tmj")
    defer core.destroy(_map)
    defer core.free_game(game);



    core.create_from_map(
        game,
        _map,
        {3,3},
        on_create = proc (obj: core.Object, transform: types.Transform){
            
        })


    core.main_loop(game)
}

