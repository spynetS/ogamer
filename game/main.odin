package main;

import "../src/ecs"
import "../src/core"
import "../src/types"
import "../src/io"
import rn "../src/renderer"
import sc "../src/scripting"

import "core:fmt"
import rl "vendor:raylib"

game : ^core.Game;
playerData := PlayerData({})

level1 := core.Scene({
    name="level1",
    load=proc(game: ^core.Game) {
        sky,_ := sc.new_gameobject(&game.ecs)
        sky.transform.size = {2000,1900}
        sky.transform.pos = {0,0}
        sky_image,_ := io.load("./game/assets/FREE_Fantasy Forest/Backgrounds/Sky.png")
        sc.add_component(sky, types.SpriteRenderable({image=sky_image, parallax = {-1,-1}, layer=-4})) 


        clouds,_ := sc.new_gameobject(&game.ecs)
        clouds.transform.size = {2200,2000}
        clouds.transform.pos = {0,400}
        clouds_image,_ := io.load("./game/assets/FREE_Fantasy Forest/Backgrounds/Clouds.png")
        sc.add_component(clouds, types.SpriteRenderable({image=clouds_image, parallax = {-0.95,-1}, layer=-3})) 
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

        background2,_ := sc.new_gameobject(&game.ecs)
        background2.transform.size = {2200,2000}
        background2.transform.pos = {0,300}
        background2_image,_ := io.load("./game/assets/FREE_Fantasy Forest/Backgrounds/Rock Mountains.png")
        sc.add_component(background2, types.SpriteRenderable({image=background2_image, parallax = {-0.9,-1}, layer=-2})) 

        tree_tilesheet := io.new_tilesheet("./game/assets/FREE_Fantasy Forest/Tiles/Trees.png", {128/2,96})
        tree,_ := sc.new_gameobject(&game.ecs)
        tree.transform.size = {200,300}
        tree.transform.pos = {-200,100}
        sc.add_component(tree, types.SpriteRenderable({image=tree_tilesheet.images[0][0]})) 
        
        create_player(&game.ecs);
        create_enemy(&game.ecs, {160,100});
        create_enemy(&game.ecs, {200,100});
        create_enemy(&game.ecs, {800,150});

        create_floor(&game.ecs, {-500,-300}, {1500,500});
        create_floor(&game.ecs, {900,-450}, {700,1000});

        mouse,_ := sc.new_gameobject(&game.ecs);
        mouse.transform.size = {30,30}
        cursor,_ := io.load("./game/assets/Light/Arrows/Arrow3.png")
        sc.add_component(mouse, types.Persistent({}))
        sc.add_component(mouse, types.UiSprite({image=cursor, layer=10}))
        sc.add_component(mouse, types.Script({
            on_update = proc(go: types.GameObject, data: rawptr, dt: f32){
                go.transform.pos = (rn.get_mouse_position() + {10,-10}) * {1,-1}
            }
        }))


        door,_ := sc.new_gameobject(&game.ecs)
        door.transform.pos = {700,100}
        door_tilesheet := io.new_tilesheet("./game/assets/11-Door/Idle.png",{46,56})
        door_opening := io.new_tilesheet("./game/assets/11-Door/Opening (46x56).png",{46,56})
        io.merge_tilesheet(door_tilesheet, door_opening)
        sc.add_component(door, types.RigidBody({}))
        sc.add_component(door, types.SquareCollider({trigger=true}))
        sc.add_component(door, types.SpriteRenderable({layer=-1}))
        animator,_ := sc.add_component(door, types.SpriteAnimator({
            sprites=door_tilesheet.images,
            active_animation=0,
            time=0.1
        }))
        sc.add_component(door, types.Script({
            data=animator,
            on_trigger_entered = proc(me, other: types.GameObject, data: rawptr, event: types.Event_Collision_Entered) {
                if other.transform.tag == "player" do (cast(^types.SpriteAnimator)data).active_animation = 1

            },
            on_event = proc(go: types.GameObject, data: rawptr, event: types.Event) {
                #partial switch v in event {
                    case types.Event_SpriteAnimator_End:
                    if (cast(^types.SpriteAnimator)data) == v.animator && v.animator.active_animation == 1 do core.change_scene(game, "level2")
                }
            }
        }))
        

        
        rl.HideCursor()
    }
    
})

level2 :=core.Scene({
    name="level2",
    load= proc(game: ^core.Game) {
        if player,has := sc.get_gameobject(&game.ecs, "player"); has {
            if rigid, has2 := ecs.get_component(&game.ecs, player.entity, types.RigidBody); has2 {
                sc.set_position(rigid, {0,-300})
            }
            else {
                create_player(&game.ecs)
            }

        }

        roof,_ := sc.new_gameobject(&game.ecs)
        roof.transform.pos = {0,0}
        roof.transform.size = {1200,800}
        
        tilesheet := io.new_tilesheet("./game/assets/FREE_Fantasy Forest/Tiles/Tileset Inside.png", {32,32})
        roof_tiles := make([dynamic]^types.Image)
        append(&roof_tiles, tilesheet.images[0][0])
        for j in 0..<(roof.transform.size.x)/100-2  {
            append(&roof_tiles, tilesheet.images[0][1])
        }
        append(&roof_tiles, tilesheet.images[0][2])
        for i in 0..<(roof.transform.size.y)/100-2 {
            append(&roof_tiles, tilesheet.images[1][0])
            for j in 0..<(roof.transform.size.x)/100-2  {
                append(&roof_tiles, tilesheet.images[1][1])
            }
            append(&roof_tiles, tilesheet.images[1][2])
        }
        append(&roof_tiles, tilesheet.images[2][0])
        for j in 0..<(roof.transform.size.x)/100-2  {
            append(&roof_tiles, tilesheet.images[2][1])
        }
        append(&roof_tiles, tilesheet.images[2][2])
        sc.add_component(roof, types.TileMap({
            width=int(roof.transform.size.x)/100,
            height=int(roof.transform.size.y)/100,
            tiles=roof_tiles,
            layer=-1
        }))

        floor,_ := sc.new_gameobject(&game.ecs)
        sc.add_component(floor, types.RigidBody({}))
        sc.add_component(floor, types.SquareCollider({}))
        floor.transform.pos = {0,-400}
        floor.transform.local_size = {0,-90}
        sc.add_child(roof, floor)

        wall1,_ := sc.new_gameobject(&game.ecs)
        sc.add_component(wall1, types.RigidBody({}))
        sc.add_component(wall1, types.SquareCollider({}))
        wall1.transform.pos = {-600,0}
        wall1.transform.local_size = {-90,0}
        sc.add_child(roof, wall1)

        wall2,_ := sc.new_gameobject(&game.ecs)
        sc.add_component(wall2, types.RigidBody({}))
        sc.add_component(wall2, types.SquareCollider({}))
        wall2.transform.pos = {600,0}
        wall2.transform.local_size = {-90,0}
        sc.add_child(roof, wall2)

              door,_ := sc.new_gameobject(&game.ecs)
        door.transform.pos = {400,-310}
        door_tilesheet := io.new_tilesheet("./game/assets/11-Door/Idle.png",{46,56})
        door_opening := io.new_tilesheet("./game/assets/11-Door/Opening (46x56).png",{46,56})
        io.merge_tilesheet(door_tilesheet, door_opening)
        sc.add_component(door, types.RigidBody({}))
        sc.add_component(door, types.SquareCollider({trigger=true}))
        sc.add_component(door, types.SpriteRenderable({layer=1}))
        animator,_ := sc.add_component(door, types.SpriteAnimator({
            sprites=door_tilesheet.images,
            active_animation=0,
            time=0.1
        }))
        sc.add_component(door, types.Script({
            data=animator,
            on_trigger_entered = proc(me, other: types.GameObject, data: rawptr, event: types.Event_Collision_Entered) {
                if other.transform.tag == "player" do (cast(^types.SpriteAnimator)data).active_animation = 1

            },
            on_event = proc(go: types.GameObject, data: rawptr, event: types.Event) {
                #partial switch v in event {
                    case types.Event_SpriteAnimator_End:
                    if (cast(^types.SpriteAnimator)data) == v.animator && v.animator.active_animation == 1 do core.change_scene(game, "level1")
                }
            }
        }))
        


    }})


main :: proc() {

    game = core.init_game();
    defer core.free_game(game);
    game.clear_color = rn.get_color(0x181818ff)
    core.register_scene(game, &level1)
    core.register_scene(game, &level2)
    core.change_scene(game, "level1")
    core.main_loop(game);

}

