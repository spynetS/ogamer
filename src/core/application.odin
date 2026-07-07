package core;

import rn "../renderer"
import "../ecs"
import "../types"
import "../ecs/systems"
import "../scripting"
import es "../event-system"
import "core:time"

Game :: struct {
    should_run: bool,
    renderer: ^rn.Renderer,
    ecs: types.ECS,
    io_handler: ^types.IOHandler
}

main_loop :: proc (game: ^Game) {
    begin :rn.BeginDraw = {};
    end :rn.EndDraw = {};
    cmd : rn.Clear = {rn.get_color(0x00aaddff)};
    
    prev := time.now()
    for game.should_run {

        
        for event in es.event_queue_poll() {
            #partial switch v in event {
                case types.Event_Should_Close_Window:
                game.should_run = false;
            }
        }
        

        append(&game.renderer.commands, begin);
        append(&game.renderer.commands, cmd);

        current := time.now()
        dt :f32 = f32(time.duration_seconds(time.Duration(current._nsec-prev._nsec)))
        prev = current



        systems.physics_system(&game.ecs,game.io_handler, game.renderer, dt);
        systems.sprite_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.tilemap_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.parent_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.camera_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.sprite_animator_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.collider_system(&game.ecs,game.io_handler, game.renderer, dt);  

        systems.script_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.render_system(&game.ecs,game.io_handler, game.renderer, dt);  
        systems.ui_system(&game.ecs,game.io_handler, game.renderer, dt);  

                

        append(&game.renderer.commands, rn.Rectangle({
            rn.get_world_mouse_position(),
				    {50,50},
            0,
            rn.get_color(0x181818ff),
            false
        }))

        append(&game.renderer.commands, end);
        es.event_queue_clear();
        rn.execute(game.renderer);
    }
}

init_game :: proc() -> ^Game {
    game := new(Game);
    game.should_run = true;
    
    game.renderer = new(rn.Renderer);
    game.io_handler = new(types.IOHandler);

    rn.init_renderer();
    systems.init_physics(&game.ecs);

    es.event_queue_init();


    // Initiation storages for the components
    ecs.add_storage(&game.ecs, ^types.Script);
    ecs.add_storage(&game.ecs, ^types.Transform);
    ecs.add_storage(&game.ecs, ^types.RigidBody);
    ecs.add_storage(&game.ecs, ^types.SquareCollider);
    ecs.add_storage(&game.ecs, ^types.RectangleRenderable);
    ecs.add_storage(&game.ecs, ^types.SpriteRenderable);
    ecs.add_storage(&game.ecs, ^types.Parent);
    ecs.add_storage(&game.ecs, ^types.Camera2D);
    ecs.add_storage(&game.ecs, ^types.SpriteAnimator);
    ecs.add_storage(&game.ecs, ^types.TextElement);
    ecs.add_storage(&game.ecs, ^types.TileMap);


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
    ecs.delete_storage(&game.ecs, ^types.Script);
    ecs.delete_storage(&game.ecs, ^types.Parent);
    ecs.delete_storage(&game.ecs, ^types.Transform);
    ecs.delete_storage(&game.ecs, ^types.RigidBody);
    ecs.delete_storage(&game.ecs, ^types.SquareCollider);
    ecs.delete_storage(&game.ecs, ^types.RectangleRenderable);
    ecs.delete_storage(&game.ecs, ^types.SpriteRenderable);
    ecs.delete_storage(&game.ecs, ^types.Camera2D);
    ecs.delete_storage(&game.ecs, ^types.SpriteAnimator);
    ecs.delete_storage(&game.ecs, ^types.TextElement);
    ecs.delete_storage(&game.ecs, ^types.TileMap);
    systems.deinit_physics();
    rn.deinit_renderer();
    es.event_queue_destroy();

    delete(game.ecs.storages);
    free(game);
}
