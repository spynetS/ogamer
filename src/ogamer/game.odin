package ogamer;
import rn "./renderer"
import "./renderer/raylib"
import "./events"
import "./ecs"
import "./io"
import "core:time"

Game :: struct {
    renderer: ^rn.Renderer,
    ecs: ^ecs.EntityComponentSystem,
    should_run: bool,
    eventQueue: ^events.EventQueue,
    assetsManager: ^io.AssetsManager
}


init_game :: proc (settings: rn.RendererSettings = rn.RendererSettings({67})) -> ^Game {
    rn.execute = raylib.execute // TODO 

    game := new(Game)
    game.renderer = rn.new_renderer(settings)
    game.should_run = true
    game.eventQueue = events.new_eventQueue()

    game.ecs = new(ecs.EntityComponentSystem);
    ecs.add_systems(game.ecs)

    game.assetsManager = new(io.AssetsManager)
    raylib.assets = game.assetsManager // FIXME dont use global variables

    return game;
}

start_game :: proc (game: ^Game) {
    rn.add_command(game.renderer, rn.InitWindow({800,500,"BLA"}))
    rn.execute(game.renderer, game.eventQueue)

    begin :rn.BeginDraw = {};
    end :rn.EndDraw = {};
    cmd : rn.Clear = {rn.get_color(0x181818ff)}



    prev_time := time.now()
    for game.should_run {


        // check if we should close
        for event in events.event_queue_poll(game.eventQueue) {
            #partial switch v in event {
                case events.Should_Close_Window:
                game.should_run = false;
            }
        }


        current_time := time.now()
        dt :f32 = f32(time.duration_seconds(time.Duration(current_time._nsec-prev_time._nsec)))
        prev_time = current_time


        // prepare the renderer
        rn.add_command(game.renderer, begin);
        rn.add_command(game.renderer, cmd);
        // render
        ecs.update_systems(ecs.SystemData({
            ecs = game.ecs,
            renderer = game.renderer,
            assets_manager = game.assetsManager,
            eventQueue = game.eventQueue
        }), dt)

        // end the rendering
        rn.add_command(game.renderer, end);

        events.event_queue_clear(game.eventQueue);
        rn.execute(game.renderer, game.eventQueue)
    }
    rn.add_command(game.renderer, rn.DeinitWindow({}))
    rn.execute(game.renderer, game.eventQueue)
}

destroy_game :: proc (game: ^Game) {
    ecs.free_ecs(game.ecs);
    rn.destroy_renderer(game.renderer)
    io.destroy_handler(game.assetsManager)
    events.event_queue_destroy(game.eventQueue)
    
    free(game)
}
