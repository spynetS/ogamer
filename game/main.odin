package main;
import og "../src/ogamer"
import "../src/ogamer/tiled"
import "../src/ogamer/io"
import "../src/ogamer/ecs"
import "../src/ogamer/events"
import "core:fmt"

game: ^og.Game

main :: proc() {
    game = og.init_game();

    tilesheet := io.new_tilesheet(game.assetsManager, "/home/spy/dev/speler/Sprites/02-King Pig/Idle (38x28).png", {38,28})
    gameobject := og.new_gameobject(game.ecs);
    og.add_component(gameobject, ecs.NewSpriteAnimator(sprites=tilesheet.sprites))
    og.add_component(gameobject, ecs.NewCamera())
    
    og.add_component(gameobject, ecs.NewScriptComponent(ecs.NewScript(update = proc(data: ecs.ScriptData) {
        data.gameObject.transform.pos += {1,0}
    })))


    gameobject2 := og.new_gameobject(game.ecs);
    gameobject2.transform.pos = {-200,0}
    og.add_component(gameobject2, ecs.NewSpriteAnimator(sprites=tilesheet.sprites))
    og.add_component(gameobject2, ecs.NewScript(update = proc(data: ecs.ScriptData) {
        data.gameObject.transform.pos += {1,0}
    }))



    og.start_game(game);
    og.destroy_game(game);
}


