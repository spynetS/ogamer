package main;
import og "../src/ogamer"
import "../src/ogamer/io"
import "../src/ogamer/ecs"
import "core:fmt"

main :: proc() {
    game := og.init_game();
    
    path := "/home/spy/dev/speler/Sprites/01-King Human/Idle (78x58).png"

    tilesheet := io.new_tilesheet(game.assetsManager, path, {78,58})

    gameObject := og.new_gameobject(game.ecs);
    gameObject.transform.size = {200,200}
    og.add_component(gameObject, ecs.NewSpriteRenderer());
    og.add_component(gameObject, ecs.NewSpriteAnimator(
        sprites=tilesheet.sprites,
    ))

    og.add_component(gameObject, ecs.NewScriptComponent(ecs.NewScript(
        update = proc(data: ecs.ScriptData) {
            //data.gameObject.transform.pos += {1,1}*data.dt*100
        }
    )))
    og.start_game(game);
    og.destroy_game(game);
}


