package main;
import "core:fmt"
import "core:mem"
import ecs "../src/ogamer/ecs"
import rn "../src/ogamer/renderer"
import "../src/ogamer/renderer/raylib"
import "../src/ogamer/ecs/components"
import "../src/ogamer/events"

main :: proc() {
    rn.execute = raylib.execute
    
    renderer := new(rn.Renderer)
    rn.add_command(renderer, rn.InitWindow({800,500,"BLA"}))
    rn.execute(renderer)

    begin :rn.BeginDraw = {};
    end :rn.EndDraw = {};
    cmd : rn.Clear = {rn.get_color(0x181818ff)}


    should_run := true
    for should_run {
        for event in events.event_queue_poll() {
            #partial switch v in event {
                case events.Event_Should_Close_Window:
                should_run = false
            }
        }
        rn.add_command(renderer, begin);
        rn.add_command(renderer, cmd);
        rn.add_command(renderer, end);
    }
    rn.add_command(renderer, rn.DeinitWindow({}))
    rn.execute(renderer)


}

