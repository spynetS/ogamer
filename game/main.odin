package main;

import "core:fmt"
import "../src/core"
import "../src/ecs"
import ec "../src/ecs/ecs_core"
import rn "../src/renderer"


main :: proc() {
    
    game := core.init_game();
    defer core.free_game(game);
    counter := 0;
    for i in 0..<800 {
        for j in 0..<100 {
            ecs.add_component(&game.ecs,u32(counter), ec.Transform({{f32(i*2),f32(j*2)}, {1,1}, {0,0}}));
            ecs.add_component(&game.ecs,u32(counter), ec.PhysicsBody({{0,0}, {0,9.8}}));
            ecs.add_component(&game.ecs,u32(counter), ec.RectangleRenderable({rn.get_color(0x181818ff)}));
            counter += 1;
        }
    }

    core.main_loop(game);
}

