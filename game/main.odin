package main;

import "core:fmt"
import "../src/core"
import "../src/ecs"
import ec "../src/ecs/ecs_core"
import rn "../src/renderer"


main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);

    ecs.add_component(&game.ecs,0, ec.Transform({{100,100}, {100,100}, {0,0}}));
    ecs.add_component(&game.ecs,0, ec.PhysicsBody({{0,0}, {0,9.8}}));
    ecs.add_component(&game.ecs,0, ec.RectangleRenderable({rn.get_color(0x181818ff)}));

    ecs.add_component(&game.ecs,1, ec.Transform({{250,100}, {50,50}, {0,0}}));
    ecs.add_component(&game.ecs,1, ec.RectangleRenderable({rn.get_color(0x181818ff)}));


    core.main_loop(game);
}
