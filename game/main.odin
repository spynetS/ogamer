package main;

import "../src/core"
import "../src/types"
import "../src/io"
import sc "../src/scripting"


game : ^core.Game;

main :: proc() {

    game = core.init_game();
    defer core.free_game(game);

    background,_ := sc.new_gameobject(&game.ecs)
    background.transform.size = {2200,2000}
    background_image,_ := io.load("./game/assets/background0.png")
    sc.add_component(background, types.SpriteRenderable({image=background_image, parallax = {-0.9,-1}}))

    create_player(&game.ecs);
    create_enemy(&game.ecs, {160,100});
    create_enemy(&game.ecs, {200,100});

    create_floor(&game.ecs, {0,-100}, {700,100});
    create_floor(&game.ecs, {900,0}, {700,100});


    core.main_loop(game);
}

