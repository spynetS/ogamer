package core;

import rl "vendor:raylib"
import rn "../renderer"
import "../ecs"
import "../ecs/types"
import "../ecs/systems"
import es "../event-system"
import "../io"
import "core:fmt"
import b2 "vendor:box2d"

Game :: struct {
    should_run: bool,
    renderer: ^rn.Renderer,
    ecs: ecs.ECS,
    io_handler: ^types.IOHandler
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

        systems.physics_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.sprite_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.parent_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.camera_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.sprite_animator_system(&game.ecs,game.io_handler, game.renderer, dt);  

        systems.script_system(&game.ecs,game.io_handler, game.renderer, dt);  

        systems.render_system(&game.ecs,game.io_handler, game.renderer, dt);  

        
        append(&game.renderer.commands, end);
        es.event_queue_clear();
        rn.execute(game.renderer);
    }
}

init_game :: proc() -> ^Game {
    game := new(Game);
    game.should_run = true;
    
    game.renderer= new(rn.Renderer);
    game.io_handler = new(types.IOHandler);
    systems.init_physics();

    es.event_queue_init();

    // Initiation storages for the components
    ecs.add_storage(&game.ecs, ^ecs.Script);
    ecs.add_storage(&game.ecs, ^types.Transform);
    ecs.add_storage(&game.ecs, ^types.RigidBody);
    ecs.add_storage(&game.ecs, ^types.RectangleRenderable);
    ecs.add_storage(&game.ecs, ^types.SpriteRenderable);
    ecs.add_storage(&game.ecs, ^types.Parent);
    ecs.add_storage(&game.ecs, ^types.Camera2D);
    ecs.add_storage(&game.ecs, ^types.SpriteAnimator);


    // init rendering window
    init :rn.InitWindow = {800,500,"BLA"};
    append(&game.renderer.commands, init);
    rn.execute(game.renderer);

    return game;
}

free_game :: proc(game: ^Game) {
    delete(game.renderer.commands);
    free(game.renderer);
    free(game.io_handler);
    ecs.delete_storage(&game.ecs, ^ecs.Script);
    ecs.delete_storage(&game.ecs, ^types.Parent);
    ecs.delete_storage(&game.ecs, ^types.Transform);
    ecs.delete_storage(&game.ecs, ^types.RigidBody);
    ecs.delete_storage(&game.ecs, ^types.RectangleRenderable);
    ecs.delete_storage(&game.ecs, ^types.SpriteRenderable);
    ecs.delete_storage(&game.ecs, ^types.Camera2D);
    ecs.delete_storage(&game.ecs, ^types.SpriteAnimator);
    systems.deinit_physics();

    es.event_queue_destroy();

    delete(game.ecs.storages);
    free(game);
}
