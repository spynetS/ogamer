package core;

import rn "../renderer"
import "../ecs"
import "../io"
import "../types"
import "../ecs/systems"
import "../scripting"
import es "../event-system"
import "core:time"
import "core:fmt"
import "core:mem/virtual"

DEBUG :: false

Game :: struct {
    should_run        : bool,
    renderer          : ^rn.Renderer,
    ecs               : types.ECS,
    registered_scenes : map[string]^Scene,
    current_scene     : ^Scene,
    next_scene        : ^Scene,
    io_handler        : ^types.IOHandler,
    clear_color       : [4]u8
}

Scene :: struct {
    name: string,
    load: proc(game: ^Game),
    unload: proc(game: ^Game)
}

register_scene :: proc(game: ^Game, scene: ^Scene) {
    game.registered_scenes[scene.name] = scene
}

change_scene :: proc(game: ^Game, name: string) {
    game.next_scene = game.registered_scenes[name]
}


main_loop :: proc (game: ^Game) {


    begin :rn.BeginDraw = {};
    end :rn.EndDraw = {};
    cmd : rn.Clear = {game.clear_color}
    
    prev := time.now()
    for game.should_run {

        if game.next_scene != nil {
            fmt.println("INFO: changing to next scene")
            if game.current_scene != nil && game.current_scene.unload != nil {
                game.current_scene.unload(game)
            }
            ecs.clear_all_entities(&game.ecs)
            game.current_scene = game.next_scene
            game.next_scene = nil
            game.current_scene.load(game)
        }


        for event in es.event_queue_poll() {
            #partial switch v in event {
                case types.Event_Should_Close_Window:
                game.should_run = false;
            }
        }

 

        rn.add_command(game.renderer, begin);
        rn.add_command(game.renderer, cmd);

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

        rn.add_command(game.renderer, end);
        es.event_queue_clear();
        rn.execute(game.renderer);

        if DEBUG do game.should_run = false

    }
}

init_game :: proc() -> ^Game {
    if DEBUG do rn.RENDER = false
    game := new(Game);
    game.should_run = true;
    game.clear_color = rn.get_color(0x00aaddff)
    game.renderer = new(rn.Renderer);
    game.io_handler = new(types.IOHandler);

    _ = virtual.arena_init_growing(&game.io_handler.arena)

    rn.init_renderer();
    rn.assets= game.io_handler
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
    ecs.add_storage(&game.ecs, ^types.UiSprite);
    ecs.add_storage(&game.ecs, ^types.Persistent);
    ecs.add_storage(&game.ecs, ^types.TileMap);


    // init rendering window
    init :rn.InitWindow = {800,500,"BLA"};
    rn.add_command(game.renderer, init);
    rn.execute(game.renderer);

    return game;
}

free_game :: proc(game: ^Game) {

    for path, image in game.io_handler.textures {
        fmt.println(path)
    }


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
    ecs.delete_storage(&game.ecs, ^types.UiSprite);
    ecs.delete_storage(&game.ecs, ^types.TileMap);
    ecs.delete_storage(&game.ecs, ^types.Persistent);
    systems.deinit_physics();
    rn.deinit_renderer();
    es.event_queue_destroy();

    
    delete(game.renderer.debug_commands);
    delete(game.renderer.deinit_commands);
    delete(game.renderer.draw_commands);
    delete(game.renderer.init_commands);
    free(game.renderer);
    io.free_handler(game.io_handler)
    delete(game.ecs.storages);
    free(game);
}
