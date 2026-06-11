package core;

import rl "vendor:raylib"
import rn "../renderer"
import "../ecs"

Game :: struct {
    should_run: bool,
    renderer: ^rn.Renderer,
    storage: ^ ecs.ComponentStorage(ecs.Transform) // have a list of storages
}

main_loop :: proc (game: ^Game) {
    for !rl.WindowShouldClose() {
        rl.BeginDrawing();
        
        cmd : rn.RenderCommand = {
            rn.RenderCommandType.CMD_CLEAR,
            {255,255,255,255},
            {{0,0},{0,100},{100,100}}
        };
        append(&game.renderer.commands, cmd);

        for entity in game.storage.entities {
            trans : ^ecs.Transform = ecs.get_component(game.storage,entity);
            rn.draw_rectangle(game.renderer, trans.pos, trans.size, rn.get_color(0xff0000ff));
        }

        
        rn.execute(game.renderer);
        
        rl.EndDrawing();
    }
}

init_game :: proc() -> ^Game {
    game := new(Game);
    game.should_run = true;
    rl.InitWindow(800,400,"Game");
    
    renderer := new(rn.Renderer);
    game.renderer = renderer;

    storage := ecs.init_storage(ecs.Transform,10);
    game.storage = storage;

    
    ecs.add_component(storage, 0, ecs.Transform({{200,100},{100,100},{0,0}}));
    ecs.add_component(storage, 1, ecs.Transform({{200,250},{100,100},{0,0}}));

    return game;
}

free_game :: proc(game: ^Game) {
    free(game.renderer);
    ecs.delete_storage(game.storage);
    free(game);
}
