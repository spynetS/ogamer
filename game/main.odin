package main;

import "../src/core"
import "../src/types"
import "../src/io"
import rn "../src/renderer"
import sc "../src/scripting"

import rl "vendor:raylib"

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
    create_enemy(&game.ecs, {800,150});

    create_floor(&game.ecs, {0,-100}, {700,100});
    create_floor(&game.ecs, {900,0}, {700,100});

    mouse,_ := sc.new_gameobject(&game.ecs);
    mouse.transform.size = {30,30}
    cursor,_ := io.load("./game/assets/Light/Arrows/Arrow3.png")
    sc.add_component(mouse, types.SpriteRenderable({image=cursor, layer=10}))
    sc.add_component(mouse, types.Script({
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32){
            go.transform.pos = rn.get_world_mouse_position() + {10,-10}
        }
    }))
    
    rl.HideCursor()

    core.main_loop(game);
}

