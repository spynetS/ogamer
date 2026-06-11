package main;

import "core:fmt"
import "../src/core"

main :: proc() {

    game := core.init_game();
    defer free(game);
    
    // core.start_game(&game);
}
