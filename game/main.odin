package main;

import "core:fmt"
import "../src/core"
import "../src/ecs"
import ec "../src/ecs/ecs_core"

main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);

    ecs.add_component(&game.storages,0, ec.Transform({{100,100}, {100,100}, {0,0}}));
    ecs.add_component(&game.storages,1, ec.Transform({{250,100}, {50,50}, {0,0}}));


    core.main_loop(game);
}
