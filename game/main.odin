package main;
import og "../src/ogamer"
import "../src/ogamer/tiled"
import "../src/ogamer/io"
import "../src/ogamer/ecs"
import "../src/ogamer/input "
import "../src/ogamer/events"
import rn "../src/ogamer/renderer"
import "core:fmt"
import b2 "vendor:box2d"

game: ^og.Game

main :: proc() {
    game = og.init_game();


    _map := tiled.load_map(game.assetsManager, "./game/map.tmj")
    defer tiled.destroy_map(_map)

    tiled.create_from_map(game, _map, {3,3}, on_create = proc(obj: tiled.Object, transform: ecs.Transform) {
        if obj.class == "player" {

            tilesheet := io.new_tilesheet(game.assetsManager, "/home/spy/dev/speler/Sprites/02-King Pig/Idle (38x28).png", {38,28})
            gameobject := og.new_gameobject(game.ecs);
            gameobject.transform.pos = transform.pos
            og.add_component(gameobject, ecs.NewSpriteAnimator(sprites=tilesheet.sprites))
            og.add_component(gameobject, ecs.NewCamera(zoom=1))
            og.add_component(gameobject, ecs.Rigidbody({type=ecs.BodyType.dynamicBody, disabled_rotation=true}))
            
            og.add_component(gameobject, ecs.NewText(text="HEJ whats happening?", offset={-100,100}))
            
            og.add_component(gameobject, ecs.NewScriptComponent(ecs.NewScript(update = proc(data: ecs.ScriptData) {
                for event in events.event_queue_poll(game.eventQueue) {
                    #partial switch v in event {
                        case events.Key_Pressed:
                        if v.key == input.KeyboardKey.D     do b2.Body_ApplyForceToCenter(data.world.bodies[data.gameObject.entity],{1000,0},true)
                        if v.key == input.KeyboardKey.A     do b2.Body_ApplyForceToCenter(data.world.bodies[data.gameObject.entity],{-1000,0},true)
                        if v.key == input.KeyboardKey.SPACE do b2.Body_ApplyForceToCenter(data.world.bodies[data.gameObject.entity],{0,1000},true)
                    }
                }
            })))
            fmt.println("PLAYER", gameobject.entity)
        }
        if obj.class == "col" {
            tilesheet := io.new_tilesheet(game.assetsManager, "/home/spy/dev/speler/Sprites/02-King Pig/Attack (38x28).png", {38,28})
            gameobject1 := og.new_gameobject(game.ecs);
            gameobject1.transform.pos = transform.pos
            gameobject1.transform.size = transform.size
            og.add_component(gameobject1, ecs.Rigidbody({type=ecs.BodyType.staticBody}))
            og.add_component(gameobject1, ecs.SpriteRenderer({}))
            fmt.println("COL", gameobject1.entity)
        }

    })



    og.start_game(game);
    og.destroy_game(game);
}


