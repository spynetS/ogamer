package main;
import og "../src/ogamer"
import "../src/ogamer/tiled"
import "../src/ogamer/io"
import "../src/ogamer/ecs"
import "../src/ogamer/input "
import "../src/ogamer/events"
import rn "../src/ogamer/renderer"
import "core:fmt"
import b2 "vendor:box2d"

game: ^og.Game

main :: proc() {
    game = og.init_game();
    og.current_game = game;
    
    create_player(game)

    _map := tiled.load_map(game.assetsManager, "./game/assets/map.tmj")
    fmt.println("MAP:",_map.tilesets)
    defer tiled.destroy_map(_map)
    tiled.create_from_map(game, _map, {6,6}, on_create = proc(obj: tiled.Object, transform: ecs.Transform) {});


    og.start_game(game);
    og.destroy_game(game);
}


