package main;

import "core:fmt"
import b2 "vendor:box2d"
import "../src/core"
import "../src/ecs"
import "../src/types"
import sc "../src/scripting"

import "../src/io"
import es "../src/event-system"
import sys "../src/ecs/systems"

PlayerData :: struct {
    collider      : ^types.SquareCollider,
    tool          : types.GameObject,
    feet_collider : ^types.SquareCollider,
    rigid         : ^types.RigidBody,
    animator      : ^types.SpriteAnimator,
    grounded      : bool,
}
EnemyData :: struct {
    health   : int,
    animator : ^types.SpriteAnimator
}


create_player :: proc (e: ^types.ECS) {
    player, _ := sc.new_gameobject(e);
    defer free(player)
    player.transform.size = {100,100}

    sc.add_component(player, types.Camera2D({zoom=1}));

    idle := io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Soldier/Soldier/Soldier.png", {100,100}, {0, 0});
    sprite_length := make([]int, 7)
    sprite_length[0] = 6
    sprite_length[1] = 8
    sprite_length[2] = 6
    sprite_length[3] = 6
    sprite_length[4] = 9
    sprite_length[5] = 4
    sprite_length[6] = 4

    sc.add_component(player,types.SpriteRenderable({size={300,300}, offset={0,7}}))
    animator,_ := sc.add_component(player, types.SpriteAnimator({
        sprites=idle.images,
        sprites_length=sprite_length,
        active_animation=0,
        time=0.1
    }))


    sc.add_component(player, types.SquareCollider({size={-50,-30}}))
    rigid, _ := sc.add_component(player, types.RigidBody({type=types.BodyType.dynamicBody, disable_rotation=true}))

    tool, _ := sc.new_gameobject(e);
    defer free(tool);
    tool.transform.tag = "weapon"
    tool.transform.local_pos = {60,0}
    tool.transform.local_size = {-40,-40}
    collider, _ := sc.add_component(tool, types.SquareCollider({trigger=true}))

    sc.add_child(player, tool);



    feet, _ := sc.new_gameobject(e);
    defer free(feet);
    feet.transform.local_pos = {0,40}
    feet.transform.local_size = {-80,-80}
    feet_collider,_ := sc.add_component(feet, types.SquareCollider({trigger=true}))

    sc.add_child(player, feet);

    data := new(PlayerData)
    data.collider=collider
    data.tool=tool^
    data.feet_collider = feet_collider
    data.rigid=rigid
    data.animator=animator

    sc.add_component(player, types.Script({
        data=data,
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32) {
            pd := cast(^PlayerData)data
            collider := pd.collider
            rigid := pd.rigid
            collider.disabled = true;
            pd.tool.transform.local_pos = {pd.animator.sprite_comp.inverted ? -60 : 60,0}
            if sc.is_key_down(types.KeyboardKey.D) {
                sc.apply_force(rigid, {50,0})
                pd.animator.active_animation=1
                pd.animator.sprite_comp.inverted=false
            }
            else if sc.is_key_down(types.KeyboardKey.A) {
                sc.apply_force(rigid, {-50,0})
                pd.animator.active_animation=1
                pd.animator.sprite_comp.inverted=true
            }
            else if sc.is_key_pressed(types.KeyboardKey.ENTER) && pd.animator.active_animation != 2 {
                pd.animator.time=0.05
                collider.disabled = false;

                fmt.println("TOOL Transform:", pd.tool.transform)
                pd.animator.active_animation=2
            }
            
            if sc.is_key_pressed(types.KeyboardKey.SPACE) && pd.grounded {
                sc.apply_force(pd.rigid, {0,-2500});
            }
            
            for event in es.event_queue_poll() {
                #partial switch v in event {
                    case es.Event_SpriteAnimator_End:
                    if v.animator == pd.animator {
                        pd.animator.time=0.1
                        pd.animator.active_animation = 0
                    }
                    case es.Event_Trigger_Entered:
                    if v.ca == pd.feet_collider {
                        pd.grounded = true;
                    }
                    case es.Event_Trigger_Left:
                    if v.ca == pd.feet_collider {
                        pd.grounded = false;
                    }
                }
            }

        },
        on_destroy = proc(go: types.GameObject, data:rawptr){
            pd := cast(^PlayerData)data
            free(pd)
        }
    }))



}

create_enemy :: proc(e: ^types.ECS, pos: types.Vector2) {

    enemy, _ := sc.new_gameobject(e);
    defer free(enemy)
    enemy.transform.pos = pos
    enemy.transform.size = {100,100}

    
    sc.add_component(enemy, types.RigidBody({type=types.BodyType.dynamicBody, disable_rotation=true}))
    sc.add_component(enemy, types.SquareCollider({size={-50,-30}}))
    ed: ^EnemyData = new(EnemyData)
    ed.health = 5

    fmt.println("EnemyData created at:", ed)  // <-- note this address


    idle  : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Idle.png", {100,100})
    hurt  : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Hurt.png", {100,100})
    death : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Death.png", {100,100})
    io.merge_tilesheet(idle,hurt)
    io.merge_tilesheet(idle,death)

    sc.add_component(enemy,types.SpriteRenderable({size={300,300}, offset={0,7}}))
    ed.animator, _ = sc.add_component(enemy, types.SpriteAnimator({
        sprites=idle.images,
        active_animation=0,
        time=0.1
    }))

        
    sc.add_component(enemy, types.Script({
        data=ed,
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32 ) {
            ed := cast(^EnemyData)data
            for event in es.event_queue_poll(){
                #partial switch v in event  {
                    case es.Event_SpriteAnimator_End:
                    if v.animator == ed.animator && v.animator.active_animation == 1 do ed.animator.active_animation = 0
                    if v.animator == ed.animator && v.animator.active_animation == 2 do  ecs.destroy_entity(go.ecs, go.entity)

                    case es.Event_Trigger_Entered:
                    fmt.println("ENITY: ", v.ea, v.eb, go.entity)
                    trigger_go,_ := sc.get_gameobject(go.ecs, v.ea)
                    if v.eb == go.entity &&  trigger_go.transform.tag == "weapon" {
                        ed.animator.active_animation = 1
                        ed.health = ed.health - 1
                        if ed.health <= 0 do ed.animator.active_animation = 2
                    }
                }
            }
        },
        on_destroy = proc(go: types.GameObject, data: rawptr) {
            free(data)
        }
    }))

    

}
game : ^core.Game;

main :: proc() {

    game = core.init_game();
    defer core.free_game(game);

    // camera, _ := sc.new_gameobject(&game.ecs);
    // defer free(camera)
    // sc.add_component(camera, types.Camera2D({zoom=1}));

    // player,_ := sc.new_gameobject(&game.ecs);
    // idle := io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Soldier/Soldier/Soldier.png", {100,100}, {0, 0});
    // sc.add_component(player, types.SpriteAnimator({
    //     sprites=idle.images,
    //     sprites_length={6,8,6,6,9,4,4},
    //     active_animation=1,
    //     time=0.1
    // }))


    create_player(&game.ecs);
    create_enemy(&game.ecs, {160,100});
    create_enemy(&game.ecs, {200,100});
    
    floor,_ := sc.new_renderobject(&game.ecs);
    floor.transform.pos = {0,200}
    floor.transform.size = {5000,50}
    sc.add_component(floor, types.RigidBody({}))
    sc.add_component(floor, types.SquareCollider({}))
    


    core.main_loop(game);
}

