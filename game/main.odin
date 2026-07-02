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
    collider : ^types.SquareCollider,
    tool     : types.GameObject,
    rigid    : ^types.RigidBody,
    animator : ^types.SpriteAnimator
}
EnemyData :: struct {
    health   : int,
    animator : ^types.SpriteAnimator
}


create_player :: proc (e: ^types.ECS) {
    player, _ := sc.new_gameobject(e);
    defer free(player)
    player.transform.size = {400,400}

    idle := io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Soldier/Soldier/Soldier.png", {100,100}, {0, 0});
    sprite_length := make([]int, 7)
    sprite_length[0] = 6
    sprite_length[1] = 8
    sprite_length[2] = 6
    sprite_length[3] = 6
    sprite_length[4] = 9
    sprite_length[5] = 4
    sprite_length[6] = 4

    animator,_ := sc.add_component(player, types.SpriteAnimator({
        sprites=idle.images,
        sprites_length=sprite_length,
        active_animation=0,
        time=0.1
    }))


    sc.add_component(player, types.SquareCollider({size={-350,-350}}))
    rigid, _ := sc.add_component(player, types.RigidBody({type=types.BodyType.dynamicBody, disable_rotation=true}))

    tool, _ := sc.new_gameobject(e);
    defer free(tool);
    tool.transform.local_pos = {40,0}
    tool.transform.local_size = {-350,-350}
    collider, _ := sc.add_component(tool, types.SquareCollider({trigger=true}))

    sc.add_child(player, tool);

    data := new(PlayerData)
    data.collider=collider
    data.tool=tool^
    data.rigid=rigid
    data.animator=animator

    sc.add_component(player, types.Script({
        data=data,
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32) {
            pd := cast(^PlayerData)data
            collider := pd.collider
            rigid := pd.rigid
            collider.disabled = true;
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
            else if sc.is_key_pressed(types.KeyboardKey.SPACE) && pd.animator.active_animation != 2 {
                collider.disabled = false;
                pd.tool.transform.local_pos = {pd.animator.sprite_comp.inverted ? -20 : 20,0}
                pd.animator.active_animation=2
            }
            
            for event in es.event_queue_poll() {
                #partial switch v in event {
                    case es.Event_SpriteAnimator_End:
                    if v.animator == pd.animator do pd.animator.active_animation = 0
                }
            }

        },
        on_destroy = proc(go: types.GameObject, data:rawptr){
            pd := cast(^PlayerData)data
            free(pd)
        }
    }))



}

create_enemy :: proc(e: ^types.ECS) {

    enemy, _ := sc.new_gameobject(e);
    defer free(enemy)
    enemy.transform.pos = {200,0}
    enemy.transform.size = {400,400}

    
    sc.add_component(enemy, types.RigidBody({type=types.BodyType.dynamicBody}))
    sc.add_component(enemy, types.SquareCollider({size={-350,-350}}))
    ed: ^EnemyData = new(EnemyData)
    ed.health = 5

    fmt.println("EnemyData created at:", ed)  // <-- note this address


    idle  : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Idle.png", {100,100})
    hurt  : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Hurt.png", {100,100})
    death : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Death.png", {100,100})
    io.merge_tilesheet(idle,hurt)
    io.merge_tilesheet(idle,death)

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
                    ed.animator.active_animation = 1
                    ed.health = ed.health - 1
                    if ed.health <= 0 do ed.animator.active_animation = 2
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

    camera, _ := sc.new_gameobject(&game.ecs);
    defer free(camera)
    sc.add_component(camera, types.Camera2D({zoom=1}));

    // player,_ := sc.new_gameobject(&game.ecs);
    // idle := io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Soldier/Soldier/Soldier.png", {100,100}, {0, 0});
    // sc.add_component(player, types.SpriteAnimator({
    //     sprites=idle.images,
    //     sprites_length={6,8,6,6,9,4,4},
    //     active_animation=1,
    //     time=0.1
    // }))


    create_player(&game.ecs);
    create_enemy(&game.ecs);
    
    floor,_ := sc.new_renderobject(&game.ecs);
    floor.transform.pos = {0,200}
    floor.transform.size = {500,50}
    sc.add_component(floor, types.RigidBody({}))
    sc.add_component(floor, types.SquareCollider({}))
    


    core.main_loop(game);
}

