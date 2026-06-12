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
    begin :rn.BeginDraw = {};
    end :rn.EndDraw = {};
    cmd : rn.Clear = {rn.get_color(0x181818ff)};

    for !rl.WindowShouldClose() {
        append(&game.renderer.commands, begin);
        append(&game.renderer.commands, cmd);
        
        ts, ok := ecs.get_storage(&game.storages, ec.Transform)
        if ok{
            for entity in ts.entities {
                trans : ^ec.Transform = ecs.get_component(&game.storages, entity,ec.Transform);
                trans.pos.x += 1
                rn.draw_rectangle(game.renderer, trans.pos, trans.size, rn.get_color(0xff0000ff));
            }
        }
        append(&game.renderer.commands, end);
        rn.execute(game.renderer);
    }
}

init_game :: proc() -> ^Game {
    game := new(Game);
    game.should_run = true;
    
    renderer := new(rn.Renderer);
    game.renderer = renderer;
    
    ecs.add_storage(&game.storages, ec.Transform);

    init :rn.InitWindow = {800,500,"BLA"};
    append(&game.renderer.commands, init);
    rn.execute(game.renderer);



    return game;
}

free_game :: proc(game: ^Game) {
    delete(game.renderer.commands);
    free(game.renderer);
    ecs.delete_storage(&game.storages, ec.Transform);
    delete(game.storages.storages);

    free(game);
}
