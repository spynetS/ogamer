package core;

import rl "vendor:raylib"
import rn "../renderer"
import "../ecs"
import "../io"
import "core:fmt"


Game :: struct {
    should_run: bool,
    renderer: ^rn.Renderer,
    ecs: ecs.ECS,
    io_handler: ^io.IOHandler
}

main_loop :: proc (game: ^Game) {
    begin :rn.BeginDraw = {};
    end :rn.EndDraw = {};
    cmd : rn.Clear = {rn.get_color(0x181818ff)};

    for game.should_run { 
        game.should_run = !rl.WindowShouldClose() // TODO make generic event for it
        append(&game.renderer.commands, begin);
        append(&game.renderer.commands, cmd);


        dt := rl.GetFrameTime(); // TODO calculate own dt
        // updating the systems 
        ecs.render_system(&game.ecs,game.io_handler, game.renderer, dt);  
        ecs.physics_system(&game.ecs,game.io_handler, game.renderer, dt);  
        ecs.script_system(&game.ecs,game.io_handler, game.renderer, dt);  
        ecs.sprite_system(&game.ecs,game.io_handler, game.renderer, dt);  
        ecs.parent_system(&game.ecs,game.io_handler, game.renderer, dt);  
        
        append(&game.renderer.commands, end);
        rn.execute(game.renderer);
    }
}

init_game :: proc() -> ^Game {
    game := new(Game);
    game.should_run = true;
    
    game.renderer= new(rn.Renderer);
    game.io_handler = new(io.IOHandler);

    // Initiation storages for the components
    ecs.add_storage(&game.ecs, ^ecs.Script);

    ecs.add_storage(&game.ecs, ^ecs.Transform);
    ecs.add_storage(&game.ecs, ^ecs.PhysicsBody);
    ecs.add_storage(&game.ecs, ^ecs.RectangleRenderable);
    ecs.add_storage(&game.ecs, ^ecs.SpriteRenderable);
    ecs.add_storage(&game.ecs, ^ecs.Parent);

    // init rendering window
    init :rn.InitWindow = {800,500,"BLA"};
    append(&game.renderer.commands, init);
    rn.execute(game.renderer);

    return game;
}

free_game :: proc(game: ^Game) {
    delete(game.renderer.commands);
    free(game.renderer);
    ecs.delete_storage(&game.ecs, ^ecs.Script);
    //ecs.delete_storage(&game.ecs, ^ecs.Parent);
    ecs.delete_storage(&game.ecs, ^ecs.Transform);
    ecs.delete_storage(&game.ecs, ^ecs.PhysicsBody);
    ecs.delete_storage(&game.ecs, ^ecs.RectangleRenderable);
    ecs.delete_storage(&game.ecs, ^ecs.SpriteRenderable);
    delete(game.ecs.storages);
    free(game);
}
