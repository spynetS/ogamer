package main;

import "core:fmt"
import "../src/core"
import "../src/ecs"

main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);
    

    core.main_loop(game);
}
