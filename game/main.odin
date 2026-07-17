package main;
import og "../src/ogamer"
import "../src/ogamer/tiled"
import "../src/ogamer/io"
import "../src/ogamer/ecs"
import "../src/ogamer/events"
import "core:fmt"

game: ^og.Game

main :: proc() {
    game = og.init_game();

    _map := tiled.load_map(game.assetsManager, "./game/map.tmj")
    defer tiled.destroy_map(_map)
    tiled.create_from_map(game, _map)

    

    og.start_game(game);
    og.destroy_game(game);
}


