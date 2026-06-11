package core;

import rl "vendor:raylib"

Game :: struct {
    
}


init_game :: proc() -> ^Game {
    game := new(Game);
    return game;
}
