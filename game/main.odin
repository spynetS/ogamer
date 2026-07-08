package main;

import "../src/ecs"
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

    sky,_ := sc.new_gameobject(&game.ecs)
    sky.transform.size = {2200,2000}
    sky.transform.pos = {0,0}
    sky_image,_ := io.load("./game/assets/FREE_Fantasy Forest/Backgrounds/Sky.png")
    sc.add_component(sky, types.SpriteRenderable({image=sky_image, parallax = {-1,-1}, layer=-3})) 


    clouds,_ := sc.new_gameobject(&game.ecs)
    clouds.transform.size = {2200,2000}
    clouds.transform.pos = {0,400}
    clouds_image,_ := io.load("./game/assets/FREE_Fantasy Forest/Backgrounds/Clouds.png")
    sc.add_component(clouds, types.SpriteRenderable({image=clouds_image, parallax = {-0.95,-1}, layer=-2})) 
    // TODO make this wrap
    sc.add_component(clouds, types.Script({
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32) {
            go.transform.pos -= {10,0} * dt
        }
    })) 


    background,_ := sc.new_gameobject(&game.ecs)
    background.transform.size = {2200,2000}
    background.transform.pos = {0,300}
    background_image,_ := io.load("./game/assets/FREE_Fantasy Forest/Backgrounds/Grass Mountains.png")
    sc.add_component(background, types.SpriteRenderable({image=background_image, parallax = {-0.9,-1}, layer=-1})) 

    tree_tilesheet := io.new_tilesheet("./game/assets/FREE_Fantasy Forest/Tiles/Trees.png", {128/2,96})
    tree,_ := sc.new_gameobject(&game.ecs)
    tree.transform.size = {200,300}
    tree.transform.pos = {-200,100}
    sc.add_component(tree, types.SpriteRenderable({image=tree_tilesheet.images[0][0]})) 
 
    create_player(&game.ecs);
    create_enemy(&game.ecs, {160,100});
    create_enemy(&game.ecs, {200,100});
    create_enemy(&game.ecs, {800,150});

    create_floor(&game.ecs, {0,-300}, {700,500});
    create_floor(&game.ecs, {900,-450}, {700,1000});

    mouse,_ := sc.new_gameobject(&game.ecs);
    mouse.transform.size = {30,30}
    cursor,_ := io.load("./game/assets/Light/Arrows/Arrow3.png")
    sc.add_component(mouse, types.UiSprite({image=cursor, layer=10}))
    sc.add_component(mouse, types.Script({
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32){
            go.transform.pos = (rn.get_mouse_position() + {10,-10}) * {1,-1}
        }
    }))
    
    rl.HideCursor()

    core.main_loop(game);
}

