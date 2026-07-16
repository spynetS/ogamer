package main;
import og "../src/ogamer"
import "../src/ogamer/io"
import "../src/ogamer/ecs"
import "core:fmt"

main :: proc() {
    game := og.init_game();
    
    sprite := io.load(game.assetsManager, "../../Pictures/balin.png")

    gameObject := og.new_gameobject(game.ecs);

    og.add_component(gameObject, ecs.NewTransform())
    og.add_component(gameObject, ecs.NewSpriteRenderer(sprite=sprite))
    og.add_component(gameObject, ecs.NewScriptComponent(ecs.NewScript(
        update = proc(data: ecs.ScriptData) {
            data.gameObject.transform.pos += {1,1}*data.dt*100
        }
    )))
    og.start_game(game);
    og.destroy_game(game);
}


