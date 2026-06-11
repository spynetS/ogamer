package core;

import rl "vendor:raylib"
import rn "../renderer"

Game :: struct {
    should_run: bool,
    renderer: ^rn.Renderer
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
        
        rn.draw_rectangle(game.renderer,{100,100},{200,200}, rn.get_color(0x181818ff));
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

    defer free(renderer);

    main_loop(game);

    return game;
}
