package core;

import rl "vendor:raylib"
import rn "../renderer"
import "../ecs"
import ec "../ecs/ecs_core"

Game :: struct {
    should_run: bool,
    renderer: ^rn.Renderer,
    storages: ecs.Storages
}

main_loop :: proc (game: ^Game) {
    for !rl.WindowShouldClose() {
        rl.BeginDrawing();
        // create a clear render command
        cmd : rn.RenderCommand = {
            rn.RenderCommandType.CMD_CLEAR,
            {0,0,0,0},
            {{0,0},{0,0},{0,0}}
        };
        append(&game.renderer.commands, cmd);
        
        ts := ecs.get_storage(&game.storages, ec.Transform)
        for entity in ts.entities {
            trans : ^ec.Transform = ecs.get_component(&game.storages, entity,ec.Transform);
            rn.draw_rectangle(game.renderer, trans.pos, trans.size, rn.get_color(0xff0000ff));
        }

        // execute all render commands
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
    
    ecs.add_storage(&game.storages, ec.Transform);

    return game;
}

free_game :: proc(game: ^Game) {
    free(game.renderer.commands);
    free(game.renderer);
    ecs.delete_storages(&game.storages);
    free(game);
}
