package core;

import rl "vendor:raylib"
import rn "../renderer"
import "../ecs"
import ec "../ecs/ecs_core"

Game :: struct {
    should_run: bool,
    renderer: ^rn.Renderer,
    ecs: ecs.ECS
}

main_loop :: proc (game: ^Game) {
    begin :rn.BeginDraw = {};
    end :rn.EndDraw = {};
    cmd : rn.Clear = {rn.get_color(0x181818ff)};

    for !rl.WindowShouldClose() { // TODO use game should_run

        append(&game.renderer.commands, begin);
        append(&game.renderer.commands, cmd);

        dt := rl.GetFrameTime(); // TODO calculate own dt
        // updating the systems 
        ecs.render_system(&game.ecs, game.renderer, dt);  
        ecs.physics_system(&game.ecs, game.renderer, dt);  
        ecs.script_system(&game.ecs, game.renderer, dt);  
        
        append(&game.renderer.commands, end);
        rn.execute(game.renderer);
    }
}

init_game :: proc() -> ^Game {
    game := new(Game);
    game.should_run = true;
    
    renderer := new(rn.Renderer);
    game.renderer = renderer;

    // Initiation storages for the components
    ecs.add_storage(&game.ecs, ecs.Script);
    ecs.add_storage(&game.ecs, ec.Transform);
    ecs.add_storage(&game.ecs, ec.PhysicsBody);
    ecs.add_storage(&game.ecs, ec.RectangleRenderable);

    // init rendering window
    init :rn.InitWindow = {800,500,"BLA"};
    append(&game.renderer.commands, init);
    rn.execute(game.renderer);

    return game;
}

free_game :: proc(game: ^Game) {
    delete(game.renderer.commands);
    free(game.renderer);
    ecs.delete_storage(&game.ecs, ec.Transform);
    delete(game.ecs.storages);
    free(game);
}
