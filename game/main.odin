package main;
import og "../src/ogamer"
import "../src/ogamer/tiled"
import "../src/ogamer/io"
import "../src/ogamer/ecs"
import "../src/ogamer/input "
import "../src/ogamer/events"
import rn "../src/ogamer/renderer"
import "core:fmt"

game: ^og.Game

main :: proc() {
    game = og.init_game();


    // _map := tiled.load_map(game.assetsManager, "./game/map.tmj")
    // defer tiled.destroy_map(_map)

    // tiled.create_from_map(game, _map, {3,3})

    tilesheet := io.new_tilesheet(game.assetsManager, "/home/spy/dev/speler/Sprites/02-King Pig/Idle (38x28).png", {38,28})
    gameobject := og.new_gameobject(game.ecs);
    og.add_component(gameobject, ecs.NewSpriteAnimator(sprites=tilesheet.sprites))
    og.add_component(gameobject, ecs.NewCamera())
    
    og.add_component(gameobject, ecs.NewText(text="HEJ whats happening?", offset={-100,100}))
    
    og.add_component(gameobject, ecs.NewScriptComponent(ecs.NewScript(update = proc(data: ecs.ScriptData) {
        for event in events.event_queue_poll(game.eventQueue) {
            #partial switch v in event {
                case events.Key_Pressed:
                if v.key == input.KeyboardKey.SPACE do data.gameObject.transform.pos += {1,0.1}
            }

            
        }

    })))


    debug := og.new_gameobject(game.ecs);
    debug.transform.pos = {100,100}
    og.add_component(debug, ecs.NewText(text="HEJ whats happening?"))
    og.add_component(debug, ecs.NewUISpriteRenderer(sprite=tilesheet.sprites[0][0]))


    og.start_game(game);
    og.destroy_game(game);
}


